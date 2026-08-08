# talos

Runs a Talos health check on every node.

## Description

Runs `talosctl health` against every node in `state.yaml`, waiting for Talos
and Kubernetes to be healthy on each. Prints `Waiting for Talos and
Kubernetes...` before the checks and `Talos and Kubernetes are ready` when all
nodes pass.

## Usage

```
k wait talos
```

## Prerequisites

- `talosconfig` at the repo root (create with `k generate talosconfig`).
- All nodes in `state.yaml` reachable from the local machine.

## Notes

- Takes no arguments.
