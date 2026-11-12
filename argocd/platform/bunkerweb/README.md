# BunkerWeb edge

BunkerWeb provides the public HTTP WAF in front of Envoy Gateway. BunkerWeb
serves ports 80 and 443 on nodes labeled `gateway.scg.sh/listener: "true"`.
Public DNS continues to point to SCC.

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

Merging the introduction of this configuration hands public ports 80 and 443
from host-networked Envoy to BunkerWeb during reconciliation. Schedule the merge
for a maintenance window. The Applications reconcile independently and requests
may fail during the handoff.

After reconciliation, confirm that the BunkerWeb DaemonSet is ready and that
representative public hosts, including Alumni, serve valid certificates and reach
their Envoy backends. Verify the testing, preview, and production CIDR policies
from allowed and denied networks and confirm that the internal Envoy listener
rejects connections from unrelated Pods. Validate E2S separately before changing
the DNS target.

To roll back the initial cutover, revert the BunkerWeb change set in Git. Check
that BunkerWeb's host-port mappings are removed and that Envoy is serving HTTPS
on SCC again.
