# BunkerWeb edge

BunkerWeb provides the public HTTP WAF in front of Envoy Gateway. The initial
configuration exposes a ClusterIP Service for testing the proxy chain. Follow
the cutover steps before assigning the node's public ports to BunkerWeb.

```text
Client -> BunkerWeb -> internal Envoy Gateway -> application Service
```

The application chart generates a BunkerWeb Ingress alongside each managed
HTTPRoute. BunkerWeb forwards the original host and path to Envoy. Envoy owns
path routing, redirects, traffic splitting, and CIDR policies. Production hosts
use blocking mode. The platform, testing, and preview hosts use detection mode.
Register new platform hosts in the [platform Ingress](../gateway/bunkerweb-platform-ingress.yaml)
when adding their HTTPRoutes.

The Ingresses reuse the TLS Secrets issued by cert-manager. BunkerWeb watches
TLS Secret changes and verifies the origin certificate using the request hostname
as SNI. An `external: true` route continues to accept HTTP from its external
TLS terminator. The edge handles HTTP and HTTPS; plan a separate transport path
if a TLS passthrough route is added in the future.

The controller watches Ingresses across application namespaces and requires
cluster-wide Secret read permissions to consume and refresh certificates. The
Git source overrides the chart's `bunkerweb` ClusterRole to limit writes to
Ingress status. Argo CD reports the intentional `RepeatedResourceWarning` for
that role. Restrict access to the BunkerWeb namespace and its MariaDB volume
because the controller stores TLS material in its configuration database.
External Secrets Operator generates the API token and storage passwords once.
Back up `bunkerweb-credentials` with the database before rebuilding the namespace.

## Public cutover

1. Reconcile the staging configuration. Port-forward `svc/bunkerweb-external`
   in `bunkerweb` to test existing hostnames against BunkerWeb with TLS
   verification enabled. Check that its DaemonSet is ready, certificates are
   loaded, and representative public apps, including Alumni, reach the expected
   Envoy backends. Use an unrestricted host first because Envoy still sees
   BunkerWeb's connection address in this phase.
1. In a planned maintenance window, change `spec.source.path` in
   [`../gateway/application.yaml`](../gateway/application.yaml) to
   `argocd/platform/bunkerweb/gateway-cutover`. The overlay moves Envoy off host
   networking and restricts its internal listener ports to BunkerWeb Pods.
   Confirm that both nodes have stopped serving Envoy on their public ports and
   that the private proxy is ready. Leave BunkerWeb's `hostPorts` disabled until
   the private origin and its client-IP policy are in place.
1. Set `bunkerweb.hostPorts: true` in [`values.yaml`](values.yaml). Keep the SCC
   DNS target. Verify HTTPS on SCC and check that forged forwarding headers
   cannot pass the testing, preview, or production CIDR boundaries. Test from
   allowed and denied networks and confirm direct access to Envoy is denied
   from an unrelated Pod. Validate E2S separately before changing DNS.

To roll back, disable `bunkerweb.hostPorts`, confirm the host-port mappings are
gone, then restore the Gateway Application source path to
`argocd/platform/gateway`. The base restores the host-networked Envoy and the
prior client-IP behavior.
