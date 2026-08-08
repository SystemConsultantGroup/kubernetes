# generate

Generates kubeconfig and talosconfig files for the cluster.

## Description

`k generate` groups commands that produce the client config files used by the
other `k` commands: `kubeconfig` for `kubectl`, `talosconfig` for `talosctl`.
Both are written to the repo root. Run `k generate` alone to list the
available subcommands, or `k generate help` for this page.

## Commands

- `kubeconfig` — generates the cluster kubeconfig with `talosctl kubeconfig`.
- `talosconfig` — generates the talosconfig with `talosctl gen config`.

## Usage

```
k generate <command> [args...]
```

## Prerequisites

- `state.yaml` defines the cluster name, endpoint and versions.
- `secrets/talos.yaml` is sops-encrypted and decodable with your age key.

## Notes

- Both generated files are chmod 600.
