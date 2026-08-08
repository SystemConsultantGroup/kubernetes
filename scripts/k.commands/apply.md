# apply

Applies the generated Talos machine configs to every node in state.yaml.

## Description

Generates a controlplane machine config per node, patched with `patches/<node>.yaml`,
`patches/worker.yaml` and `patches/cilium.yaml`, then applies it live with
`talosctl apply-config`. Nodes that are not yet reachable are configured with
`--insecure` on first boot.

## Prerequisites

- `state.yaml` defines the cluster name, versions and nodes.
- `secrets/talos.yaml` is sops-encrypted and decodable with your age key.
- `patches/<node>.yaml` exists for every node in state.yaml.

## Usage

```
k apply
```

## Notes

- Reconfigures **all** nodes in state.yaml, one after the other.
- Safe to re-run; nodes already running the same config are simply re-applied.
