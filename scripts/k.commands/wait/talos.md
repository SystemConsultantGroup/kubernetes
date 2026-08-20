# talos

Runs a Talos health check against every node in `state.yaml`.

## Behavior

For each declared node, runs `talosctl health` and waits for Talos and
Kubernetes health. The command labels health errors emitted while services are
starting as expected transient output; it fails only if the health check exits
non-zero. It prints a success message after all nodes pass.

## Usage

```bash
k wait talos
```

## Prerequisites

- `talosconfig` exists at the repository root; ensure it with
  `k ensure talosconfig`.
- Every node in `state.yaml` is reachable.

The command accepts no arguments and returns a non-zero status when a health
check fails.
