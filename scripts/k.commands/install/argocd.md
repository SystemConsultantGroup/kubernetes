# argocd

Installs Argo CD and bootstraps the repository's GitOps root.

## Behavior

The command:

1. creates the `argocd` namespace, OAuth secret, and GitHub webhook secret;
1. installs or upgrades the `argocd` Helm release at `argocd.version` from
   `state.yaml`;
1. restarts the ApplicationSet controller so webhook secret changes take effect;
1. creates `cert-manager` and `external-dns` namespaces and their Cloudflare
   secrets, plus the ZeroSSL EAB secret;
1. creates the `vault` namespace and its Transit seal token Secret;
1. applies [`argocd/root-application.yaml`](../../../argocd/root-application.yaml); and
1. removes `argocd-initial-admin-secret`.

Secrets come from encrypted `secrets/bootstrap.yaml` and `secrets/vault.yaml`
and are passed through standard input rather than committed to values files.
The command waits up to 10 minutes for the Argo CD Helm release and has no
confirmation prompt.
The GitHub webhook secret is also used by the ApplicationSet webhook.

## Usage

```bash
k install argocd
```

## Prerequisites

- `secrets/bootstrap.yaml` is decryptable and contains real values for
  `ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`, `ARGOCD_GITHUB_WEBHOOK_SECRET`,
  `CLOUDFLARE_API_TOKEN`, and `ZEROSSL_EAB_HMAC_KEY`.
- `secrets/vault.yaml` is decryptable and contains the Transit seal token and
  Worker key backup.
- Cilium is installed and the cluster is reachable.
- [`argocd/values.yaml`](../../../argocd/values.yaml) and
  [`argocd/root-application.yaml`](../../../argocd/root-application.yaml) exist.

This is a live operation.
After bootstrap, change desired state in Git rather than editing Argo CD
resources directly in the cluster.
