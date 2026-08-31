[한국어](README.md) | English

# Envoy Gateway

This Application installs the pinned Envoy Gateway controller and its
Envoy Gateway-specific CRDs. The upstream Gateway API CRDs remain owned by the
separate [`gateway-api`](../gateway-api/) Application.

Envoy Gateway owns the `envoy-gateway` GatewayClass. The public
[`gateway-system/public`](../gateway/) Gateway uses that class and delegates
application listeners through Gateway API `ListenerSet` resources.

Cilium remains installed as the cluster CNI, kube-proxy replacement, and
network-policy engine. Disabling `gatewayAPI` in the Cilium values disables only
Cilium's Gateway API controller; it does not remove Cilium networking.

The public Envoy data plane is configured by the platform Gateway's
`EnvoyProxy` resource. Keep its exposure, node placement, source-IP behavior,
and Wasm cache settings aligned with the cluster's bare-metal networking before
changing the public endpoint.
