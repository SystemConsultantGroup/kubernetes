# wait

Waits for Talos or Kubernetes health checks to succeed.

## Subcommands

- `kubernetes` waits for every pod in every namespace to become Ready.
- `talos` runs a Talos health check for every declared node.

## Usage

```text
k wait <command> [args...]
```

Running `k wait` lists subcommands. Use `k wait --help` for this page.

## Prerequisites

- `kubernetes` needs a reachable repository kubeconfig.
- `talos` needs a repository talosconfig and reachable declared nodes.

Both commands return a non-zero status if their checks fail or time out.
