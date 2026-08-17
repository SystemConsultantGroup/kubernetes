# talos

Runs a Talos health check against every node in `state.yaml`.

## Behavior

For each declared node, runs `talosctl health` and waits for Talos and
Kubernetes health. It prints a single start message and a success message after
all nodes pass.

## Usage

```bash
k wait talos
```

## Prerequisites

- `talosconfig` exists at the repository root; create it with
  `k generate talosconfig`.
- Every node in `state.yaml` is reachable.

The command accepts no arguments and returns a non-zero status when a health
check fails.
