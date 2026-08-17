# apply

Applies a generated Talos machine configuration to every node in `state.yaml`.

## Behavior

For each declared node, the command:

1. decrypts `secrets/talos.yaml` into a temporary file;
1. generates a control-plane configuration from `state.yaml`;
1. applies the node patch, shared worker patch, and shared Cilium patch; and
1. applies the result to that node before continuing to the next one.

A reachable node uses the normal Talos connection.
An unreachable node uses `--insecure`, which supports first-boot configuration.
The command has no confirmation prompt or dry-run mode and always targets every
declared node.

## Usage

```bash
k apply
```

## Prerequisites

- Run inside `nix develop`.
- `state.yaml` defines the cluster, versions, endpoint, and nodes.
- `secrets/talos.yaml` is decryptable with the local age key.
- `patches/<node>.yaml`, `patches/worker.yaml`, and `patches/cilium.yaml` exist.

Review node addresses, disk selectors, and the intended version changes before
running this live operation.
Temporary decrypted and generated files are removed when the command exits.
