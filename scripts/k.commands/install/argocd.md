# argocd

Installs Argo CD with GitHub OAuth and bootstraps the cluster GitOps configuration.

## Description

Creates the `argocd` namespace and injects the GitHub OAuth client secret
(from sops `secrets/bootstrap.yaml`) as the `argocd-github-oauth` secret,
labeled `app.kubernetes.io/part-of=argocd`. Installs the `argo-cd` Helm chart
from `oci://ghcr.io/argoproj/argo-helm/argo-cd` at the version pinned in
state.yaml (`argocd.version`), using `argocd/bootstrap/values.yaml`, waiting
up to 10 minutes. Creates `cert-manager` and `external-dns` namespaces, each
with a `cloudflare-api-token` secret, plus a `zerossl-eab` secret
(`hmac-key`) in cert-manager, all from sops bootstrap values. Applies
`argocd/bootstrap/root-application.yaml` (the `cluster-bootstrap` Argo CD
Application) and deletes the `argocd-initial-admin-secret`.

## Prerequisites

- `secrets/bootstrap.yaml` is sops-encrypted and decodable with your age key.
- `secrets/bootstrap.yaml` sets `ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`, `CLOUDFLARE_API_TOKEN` and `ZEROSSL_EAB_HMAC_KEY` (via `k secrets edit bootstrap`).
- `argocd/bootstrap/values.yaml` and `argocd/bootstrap/root-application.yaml` exist.
- Cilium is installed and the cluster is reachable.

## Usage

```
k install argocd
```

## Notes

- Accepts no arguments.
- Secret values are passed via stdin and unset from the environment immediately after use.
- The initial admin secret is deleted; access is through the GitHub OAuth SSO configured in `values.yaml`.
