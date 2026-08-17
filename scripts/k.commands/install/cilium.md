# cilium

Installs the pinned Cilium release with kube-proxy replacement and Gateway API
support.

## Behavior

The command first runs `k install gateway-api`, then invokes the Cilium CLI with
`cilium.version` from `state.yaml`.
It enables Kubernetes IPAM, kube-proxy replacement, Gateway API, host-networked
Envoy, and the repository's required Cilium security and cgroup settings.
It waits until all pods report Ready with `k wait kubernetes Cilium`.

## Usage

```bash
k install cilium
```

## Prerequisites

- Kubernetes is installed and reachable through the repository kubeconfig.
- `state.yaml` contains `cilium.version` and `gateway-api.version`.
- The Cilium CLI is available; `nix develop` supplies it.

The command accepts no arguments and changes cluster resources.
It uses the Cilium CLI rather than a direct Helm command.
