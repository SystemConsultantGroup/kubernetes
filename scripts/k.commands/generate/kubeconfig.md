# kubeconfig

Generates the cluster kubeconfig with `talosctl kubeconfig`.

## Behavior

The command contacts the main node selected by `.endpoint` in `state.yaml` and
writes `kubeconfig` at the repository root.
It overwrites the existing file, does not merge with the default kubeconfig, and
sets mode `600`.

## Usage

```bash
k generate kubeconfig
```

## Prerequisites

- `talosconfig` exists at the repository root; create it with
  `k generate talosconfig`.
- The main node is reachable and the Talos credentials are valid.

The command accepts no arguments.
The generated file is used by `kubectl` and other `k` commands.
