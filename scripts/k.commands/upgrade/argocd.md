# argocd

Upgrades the Argo CD Helm chart to `argocd.version` in `state.yaml`.

## Behavior

The command reads the installed `argocd` Helm release in the `argocd` namespace.
If its chart version already matches, it exits without changes.
Otherwise it prompts, unless `--yes` is supplied, and runs `k install argocd`.

That install command also refreshes bootstrap secrets and namespaces, reapplies
the root Application, waits up to 10 minutes for Helm, and removes the initial
admin secret.
This is broader than a chart-only upgrade.

## Usage

```bash
k upgrade argocd [--yes]
```

## Prerequisites

- The `argocd` Helm release exists in the `argocd` namespace.
- `state.yaml` contains `argocd.version`.
- `secrets/bootstrap.yaml` is decryptable and contains the required bootstrap
  values, including `ARGOCD_GITHUB_WEBHOOK_SECRET`.
- The cluster is reachable.

The command fails when the Argo CD release is not found.
