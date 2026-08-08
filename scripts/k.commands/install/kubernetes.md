# kubernetes

Installs the Kubernetes cluster on the Talos nodes: generate configs, apply, bootstrap etcd, wait, and write a kubeconfig.

## Description

Runs `k generate talosconfig`, which writes the admin Talos config
(`talosconfig` at the repo root, chmod 600, endpoints set to the main node),
then `k apply`, which generates a controlplane machine config per node and
applies it with `talosctl apply-config` (using `--insecure` for nodes not yet
reachable). If `talosctl etcd members` on the main node fails, bootstraps the
etcd cluster with `talosctl bootstrap`, retrying every 10 seconds for up to
10 minutes. Then waits for Talos and Kubernetes health on every node
(`k wait talos`) and writes a kubeconfig (`kubeconfig` at the repo root,
chmod 600) with `talosctl kubeconfig`.

## Prerequisites

- `secrets/talos.yaml` is sops-encrypted and decodable with your age key.
- `patches/<node>.yaml`, `patches/worker.yaml` and `patches/cilium.yaml` exist.
- state.yaml pins the Talos schematic, Talos version and Kubernetes version.

## Usage

```
k install kubernetes
```

## Notes

- Accepts no arguments.
- etcd bootstrap only runs when the main node is not already an etcd member.
- `TALOSCONFIG` and `KUBECONFIG` point at the repo-root `talosconfig` and `kubeconfig` files.
