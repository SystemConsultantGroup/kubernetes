[한국어](apply.md) | English

# apply

Applies a generated Talos machine configuration to every node in `state.yaml`.

## Behavior

The command first decrypts `secrets/talos.yaml`, generates every declared
node's control-plane configuration, applies the node and shared patches, and
validates every result in strict metal mode. It does not modify a node unless
all configurations pass local validation.

A configured node uses the authenticated Talos connection. A node uses
`--insecure` only when its unauthenticated machine-status endpoint confirms that
it is in maintenance mode. Any other authentication failure stops the command.
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
