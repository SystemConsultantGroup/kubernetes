[한국어](argocd.md) | English

# argocd

Forwards the Argo CD server to `http://localhost:8080`.

## Behavior

Runs:

```bash
kubectl port-forward service/argocd-server -n argocd 8080:443
```

The forward maps local port 8080 to the `argocd-server` service in the `argocd`
namespace.
Argo CD is configured for HTTP behind the service, so open
`http://localhost:8080`.
The process stays in the foreground; press Ctrl+C to stop it.

## Usage

```bash
k forward argocd
```

## Prerequisites

- `kubeconfig` exists and the cluster is reachable.
- Argo CD is installed and its `argocd-server` service is healthy.

The command accepts no arguments.
