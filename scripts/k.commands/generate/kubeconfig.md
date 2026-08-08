# kubeconfig

Generates the cluster kubeconfig with talosctl kubeconfig.

## Description

Runs `talosctl kubeconfig` against the main node (`.endpoint` in
`state.yaml`) and writes the kubeconfig to `kubeconfig` in the repo root with
mode 600. The existing file is overwritten (`--force`) and merging into the
default kubeconfig is disabled (`--merge=false`).

## Usage

```
k generate kubeconfig
```

## Prerequisites

- `talosconfig` exists at the repo root (create with `k generate talosconfig`).
- Main node reachable from the local machine.

## Notes

- Takes no arguments.
- The generated file is used by `kubectl` in the other `k` commands.
