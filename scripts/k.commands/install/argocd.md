# argocd

Installs Argo CD and bootstraps the repository's GitOps root.

## Behavior

The command:

1. creates the `argocd` namespace and OAuth secret;
1. installs or upgrades the `argocd` Helm release at `argocd.version` from
   `state.yaml`;
1. creates `cert-manager` and `external-dns` namespaces and their Cloudflare
   secrets, plus the ZeroSSL EAB secret;
1. applies [`argocd/root-application.yaml`](../../../argocd/root-application.yaml); and
1. removes `argocd-initial-admin-secret`.

Secrets come from encrypted `secrets/bootstrap.yaml` and are passed through
standard input rather than committed to values files. The command waits up to
10 minutes for the Argo CD Helm release and has no confirmation prompt.

## Usage

```bash
k install argocd
```

## Prerequisites

- `secrets/bootstrap.yaml` is decryptable and contains real values for
  `ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`, `CLOUDFLARE_API_TOKEN`, and
  `ZEROSSL_EAB_HMAC_KEY`.
- Cilium is installed and the cluster is reachable.
- [`argocd/values.yaml`](../../../argocd/values.yaml) and
  [`argocd/root-application.yaml`](../../../argocd/root-application.yaml) exist.

This is a live operation. After bootstrap, change desired state in Git rather
than editing Argo CD resources directly in the cluster.
