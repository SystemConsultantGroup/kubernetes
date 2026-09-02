[한국어](README.md) | English

# Cilium

Cilium provides cluster networking, kube-proxy replacement, and network-policy
and eBPF enforcement. Envoy Gateway owns the Gateway API implementation; Cilium
remains the CNI and network-policy engine. Its chart version is pinned in
`state.yaml`; the Application revision must match that pin.

## Bootstrap and ownership

A functioning CNI is required before Argo CD pods can run. `k install cilium`
therefore renders and applies the pinned Gateway API and Cilium manifests during
bootstrap. Once the root Application exists, this Application reconciles the
same Cilium chart and values with pruning and self-healing.

After bootstrap, change the version and values in Git and let Argo CD perform
upgrades. Do not use the Cilium CLI to create a second source of desired state.

## Talos settings

The values preserve the Talos requirements established by
[`../../../patches/cilium.yaml`](../../../patches/cilium.yaml): Kubernetes IPAM,
kube-proxy replacement, host cgroups, KubePrism on `localhost:7445`, and explicit
capabilities. Cilium's Gateway API controller is disabled because the platform
Gateway is managed by Envoy Gateway.

Cilium Envoy is disabled because Envoy Gateway owns the host-networked public
proxy. The cluster has no remaining Cilium L7 policies; do not enable both
host-networked Envoy implementations on the same listener node.
