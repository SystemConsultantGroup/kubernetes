# cilium

Bootstraps the pinned Gateway API definitions and Cilium before Argo CD can run.

## Behavior

The command runs `k render manifests`, then applies the rendered Gateway API and
Cilium bootstrap manifests with server-side apply. Both use the
`argocd-controller` field manager so the root Applications can assume ongoing
ownership without a competing imperative manager. It waits until all Cilium
pods report Ready.

The shared values enable Kubernetes IPAM, kube-proxy replacement, Gateway API,
host-networked Envoy, and the repository's required Talos security and cgroup
settings.

## Usage

```bash
k install cilium
```

## Prerequisites

- Kubernetes is installed and reachable through the repository kubeconfig.
- `state.yaml` contains the Gateway API and Cilium versions.
- Network access to the pinned release and chart is available.

The command accepts no arguments and changes cluster-scoped resources. After
Argo CD bootstrap, update Cilium and Gateway API through Git desired state rather
than rerunning this command for upgrades.
