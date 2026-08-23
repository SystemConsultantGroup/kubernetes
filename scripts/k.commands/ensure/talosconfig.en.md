[한국어](talosconfig.md) | English

# talosconfig

Ensures local Talos credentials match declared cluster state.

## Behavior

The command renders an expected configuration from the cluster name, endpoint,
install image, and versions in `state.yaml`, plus encrypted
`secrets/talos.yaml`. It configures the main node as the endpoint and compares
the result with `talosconfig`.

A matching file is retained. A missing or stale file is replaced atomically.
The resulting file has mode `600`; decrypted input exists only in temporary
files that are removed before the command exits.

## Usage

```bash
k ensure talosconfig
```

## Prerequisites

- `state.yaml` defines the cluster name, endpoint, and versions.
- `secrets/talos.yaml` is decryptable with the local age key.

The command accepts no arguments and does not contact or change the cluster.
Use a Talos operation or health command when live connectivity must also be
verified.
