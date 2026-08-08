# talosconfig

Generates the talosconfig with talosctl gen config.

## Description

Runs `talosctl gen config` with the cluster name, endpoint, install image and
versions from `state.yaml`, using the decrypted secrets from
`secrets/talos.yaml` (`--with-secrets`). Writes `talosconfig` to the repo root
with mode 600 and sets the main node as its endpoint. Existing files are
overwritten (`--force`).

## Usage

```
k generate talosconfig
```

## Prerequisites

- `state.yaml` defines the cluster name, endpoint and versions.
- `secrets/talos.yaml` is sops-encrypted and decodable with your age key.

## Notes

- Takes no arguments.
- Re-run automatically by `k reset` when `talosconfig` is missing.
