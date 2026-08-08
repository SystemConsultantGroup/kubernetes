# wait

Waits for cluster components to become healthy.

## Description

`k wait` groups commands that block until parts of the cluster report healthy.
Run `k wait` alone to list the available subcommands, or `k wait help` for this
page.

## Commands

- `kubernetes` — waits until all pods in every namespace are Ready.
- `talos` — runs a Talos health check on every node.

## Usage

```
k wait <command> [args...]
```

## Prerequisites

- `kubernetes` needs a reachable cluster via `kubeconfig`.
- `talos` needs `talosconfig` at the repo root.

## Notes

- Both commands fail (non-zero) if their checks time out or report unhealthy.
