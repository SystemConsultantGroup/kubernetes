# Cilium

Cilium provides cluster networking, kube-proxy replacement, and the Gateway API
implementation. Its chart version is pinned in `state.yaml`; the Application
revision must match that pin.

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
kube-proxy replacement, host cgroups, KubePrism on `localhost:7445`, explicit
capabilities, host-networked Gateway Envoy, ALPN, and appProtocol support.
Review the Talos patch and these values together when changing networking.

## Public listener placement

Host-networked Gateway listeners run only on nodes labeled:

```text
gateway.scg.sh/listener=true
```

Cilium publishes selected node addresses in Gateway status, and ExternalDNS can
publish those addresses for public routes. Add this label to a node only after
its external reachability, Cilium health, and Gateway traffic have been tested.
The Cilium agent and Envoy DaemonSet still run on every eligible Kubernetes node
regardless of this listener selector.
