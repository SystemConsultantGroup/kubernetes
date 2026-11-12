# Public Gateway

This directory defines the Envoy Gateway-backed `gateway-system/public`
Gateway and its listener policies for platform services and managed
applications. Cilium remains the cluster CNI and network-policy engine; Envoy
Gateway owns the Gateway API controller and Envoy data plane.

## Listeners

| Listener | Hostname | Certificate |
| --- | --- | --- |
| `platform-https` | `*.platform.scg.sh` | `platform-wildcard-tls` |
| `testing-https` | `*.testing.scg.sh` | `application-wildcards-tls` |
| `preview-https` | `*.preview.scg.sh` | `application-wildcards-tls` |
| `scg-skku-passthrough` | `*.scg.skku.ac.kr` | TLS passthrough; no backend route is configured |

cert-manager creates the referenced Secrets in `gateway-system`. Managed
production domains attach through ListenerSets created by the application
chart, with separate certificates where the platform owns TLS.

## Public endpoint placement

[BunkerWeb](../bunkerweb/README.md) serves node ports 80 and 443 and forwards to
Envoy through an internal Service. Both data planes run as DaemonSets on nodes
labeled `gateway.scg.sh/listener: "true"`. The Talos patches for SCC (`k8s`) and
E2S (`e2s`) declare that label as desired state. Keep this opt-in label when adding
nodes and validate their cross-node datapath and public ingress before publishing
their addresses.

Talos patches are not reconciled by Argo CD, so merging a label change does not
open the listener on a running node. During a separately authorized operation,
a platform engineer must keep the SCC-only DNS pin in place, review every node's
address and disk selector, and run `k apply` from `nix develop`. That command has
no confirmation prompt and reapplies the generated configuration to every node
in `state.yaml`, validating all configurations before changing any node. Then
confirm the E2S label and test an HTTPS hostname directly against the E2S address
before considering DNS changes.

The Gateway's target annotation intentionally keeps public DNS on SCC while
E2S ingress is validated. The label controls where BunkerWeb serves port 443.
Remove the temporary DNS pin in a separate reviewed change after the direct E2S
test succeeds.

The `scg-skku-passthrough` listener has no configured TLSRoute after removal of
the legacy forwarding application. Moving DNS to the public Gateway does not
make these hostnames serve an application; configure the intended routing and
TLS handling before directing traffic here. The listener does not publish
wildcard DNS or cover the zone apex.

## Client network boundary

The `testing-access` and `preview-access` Envoy Gateway `SecurityPolicy`
resources allow external clients only from `115.145.150.0/24`. The current
cluster PodCIDR (`10.244.0.0/23`) is also explicitly allowed so in-cluster
clients can use the restricted listeners.
Platform hosts remain public. Managed production workloads are public by default
and may opt into `http.allowCIDRs` in application metadata. Their rule-level
SecurityPolicies belong to the application chart, not this directory; see the
[chart reference](../../charts/application/README.md#httpallowcidrs). These policies
never render for testing or preview, where a more-specific route policy could
otherwise override the platform listener boundary.

The testing and preview policies target the shared Gateway's listener sections
rather than a Cilium identity. Preserve their default-deny behavior, allowed
CIDRs, and listener targets.

The internal Envoy listener accepts traffic from BunkerWeb Pods. BunkerWeb
overwrites `X-Forwarded-For` with the address it saw on the client connection,
and Envoy trusts that header from the cluster PodCIDR on the isolated path.
A proxy in front of BunkerWeb appears as the client, including for `external: true`
domains. Establish a platform-reviewed forwarding trust boundary before allowing
proxied client CIDRs.

On an authorized production rollout, check that each generated policy is accepted
for the expected route rule and test requests from both allowed and denied source
networks, including attempts with forged forwarding headers. Policy submission
precedes new routes but reconciliation is not atomic. Removing `allowCIDRs`
prunes the policy and intentionally restores public access. Production policies
do not inherit the testing/preview PodCIDR exception and do not isolate direct
in-cluster Service traffic.

## Namespace boundary

Routes and ListenerSets may attach only from namespaces labeled:

```yaml
gateway.scg.sh/public: "true"
```

Managed application namespaces receive this label from their ApplicationSet.
The selector is part of the public-exposure boundary; do not broaden it merely
to make an unreviewed route attach. Envoy Gateway's `GatewayClass` and
`EnvoyProxy` resources are platform-owned.

## Wasm fetch compatibility

Envoy Gateway serves HTTP Wasm modules through its internal `envoy-gateway`
Service. Envoy Gateway v1.9.1 generates this as an `envoy.cluster.dns` custom
cluster, but the v1.39.1 proxy in this IPv4-only cluster did not populate its
host. The shared proxy therefore patches `wasm_cluster` to the legacy
`STRICT_DNS` type with `V4_ONLY`; without this compatibility patch, fail-closed
Wasm filters return HTTP 503 before the application route is reached.

## Changes and diagnosis

A route must have an accepted parent, a matching listener hostname, and a valid
backend reference before it serves traffic. Check Gateway, ListenerSet, policy,
and route conditions before inspecting DNS. Verify the BunkerWeb node ports and
the internal Envoy Service endpoints. DNS publication and certificate issuance
are handled by the controllers documented under
[`../external-dns-scg.sh/`](../external-dns-scg.sh/README.md) and
[`../cert-manager/`](../cert-manager/README.md).
