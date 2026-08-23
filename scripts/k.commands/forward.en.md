[한국어](forward.md) | English

# forward

Forwards cluster services to ports on the local machine.

## Commands

- `argocd` forwards the Argo CD server to `http://localhost:8080`.

## Usage

```text
k forward <command> [args...]
```

Running `k forward` lists subcommands.
Use `k forward --help` for this page.

## Prerequisites

- The development shell is active and `kubeconfig` exists.
- The cluster is reachable.
- The target service is installed and healthy.

## Behavior

Forwards run in the foreground.
Press Ctrl+C to stop the active forward.
The command does not change cluster resources.
