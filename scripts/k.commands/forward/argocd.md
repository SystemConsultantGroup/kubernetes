# argocd

Port-forwards the Argo CD server to http://localhost:8080.

## Description

Runs `kubectl port-forward service/argocd-server -n argocd 8080:443`, mapping
local port 8080 to the `argocd-server` service in the `argocd` namespace. The
forward runs in the foreground and stops when you press Ctrl+C.

## Usage

```
k forward argocd
```

## Prerequisites

- Cluster reachable via `kubeconfig` (generate with `k generate kubeconfig`).
- Argo CD installed and the `argocd-server` service healthy.

## Notes

- Takes no arguments.
- Prints `Forwarding Argo CD at http://localhost:8080. Press Ctrl+C to stop.`
  while running.
