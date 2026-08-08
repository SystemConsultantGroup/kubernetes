# forward

Port-forwards cluster services to localhost.

## Description

`k forward` groups commands that tunnel a service running in the cluster to a
port on your local machine with `kubectl port-forward`. Run `k forward` alone
to list the available subcommands, or `k forward help` for this page.

## Commands

- `argocd` — port-forwards the Argo CD server to http://localhost:8080.

## Usage

```
k forward <command> [args...]
```

## Prerequisites

- Cluster reachable via `kubeconfig` (generate with `k generate kubeconfig`).
- The targeted service is installed and running in the cluster.

## Notes

- Every forward runs in the foreground; press Ctrl+C to stop it.
