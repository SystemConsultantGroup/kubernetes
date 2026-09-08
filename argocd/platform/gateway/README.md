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

cert-manager creates the referenced Secrets in `gateway-system`. Managed
production domains attach through ListenerSets created by the application
chart, with separate certificates where the platform owns TLS.

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

The current host-networked data plane has no client-IP detection override. Envoy
Gateway uses the downstream connection's remote address, not a client-supplied
`X-Forwarded-For` or `X-Real-IP` header. A proxy or load balancer that terminates
connections or performs SNAT therefore appears as the client, including for
`external: true` domains. Before allowing proxied client CIDRs, establish a
platform-reviewed forwarding trust boundary (trusted proxy CIDRs or an explicitly
secured PROXY-protocol path); never trust arbitrary forwarded headers. Allowing a
proxy's egress CIDR alone allows all clients that can reach that proxy.

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
and route conditions before inspecting DNS. The Envoy data-plane Service or
host-networked DaemonSet must also have the expected public endpoint. DNS
publication and certificate issuance are separate controllers documented under
[`../external-dns-scg.sh/`](../external-dns-scg.sh/README.md) and
[`../cert-manager/`](../cert-manager/README.md).
