# talosconfig

Generates the Talos client configuration with `talosctl gen config`.

## Behavior

The command uses the cluster name, endpoint, install image, and versions from
`state.yaml`, plus decrypted `secrets/talos.yaml`. It overwrites the
repository-root `talosconfig`, sets mode `600`, and configures the main node as
its endpoint. Decrypted secrets are stored only in a temporary file during the
command.

## Usage

```bash
k generate talosconfig
```

## Prerequisites

- `state.yaml` defines the cluster name, endpoint, and versions.
- `secrets/talos.yaml` is decryptable with the local age key.

The command accepts no arguments. `k reset` generates this file automatically
when it is missing.
