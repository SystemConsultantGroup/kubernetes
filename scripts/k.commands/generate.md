# generate

Generates kubeconfig and talosconfig files for the cluster.

## Description

`k generate` groups commands that produce repository and client configuration artifacts. Run `k generate` alone to list the available subcommands, or `k generate help` for this page.

## Commands

- `application-schemas` — vendors the application API types pinned by `state.yaml` and generates the chart values schema.
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

- Generated client configuration files are chmod 600.
- Application schemas are committed and can be checked with `k generate application-schemas --check`.
