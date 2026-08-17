# kubernetes

Installs Kubernetes on the Talos nodes and writes a kubeconfig.

## Behavior

The command runs these steps in order:

1. generates `talosconfig` from `state.yaml` and encrypted Talos secrets;
1. runs `k apply` for every declared node;
1. bootstraps etcd on the main node when it is not already a member;
1. waits for Talos and Kubernetes health on every node; and
1. generates the repository-root `kubeconfig`.

Etcd bootstrap retries every 10 seconds for up to 10 minutes. `k apply` uses
`--insecure` for nodes that are not reachable yet, which supports first boot.

## Usage

```bash
k install kubernetes
```

## Prerequisites

- `secrets/talos.yaml` is decryptable with the local age key.
- Every declared node has `patches/<node>.yaml`, plus the shared worker and
  Cilium patches.
- `state.yaml` pins the Talos schematic, Talos version, and Kubernetes version.
- The declared node addresses are correct and the nodes are powered on when
  their configuration is applied; first-boot nodes may use the insecure path.

The command accepts no arguments and performs live node and cluster changes.
`talosconfig` and `kubeconfig` are written with mode `600`.
