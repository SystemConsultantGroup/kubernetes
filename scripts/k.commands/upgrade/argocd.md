# argocd

Upgrades the Argo CD Helm chart to the version pinned in state.yaml.

## Description

Reads the installed chart version via `helm list` in the `argocd` namespace
and compares it to the `argocd.version` pinned in state.yaml. If they match,
prints the current version and exits without changes. Otherwise prompts for
confirmation (or applies with `--yes`) and runs `k install argocd` to
reinstall the chart at the pinned version.

## Prerequisites

- Argo CD installed as a Helm release named `argocd` in the `argocd` namespace.
- state.yaml pins `argocd.version` (the chart version).
- `secrets/bootstrap.yaml` is decodable, as `k install argocd` requires it.

## Usage

```
k upgrade argocd [--yes]
```

## Notes

- Fails if the `argocd` Helm release is not found.
- `k install argocd` also refreshes the OAuth secret, namespaces and bootstrap Application, not just the chart.
