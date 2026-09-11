# argocd

Bootstraps Argo CD and creates the repository's GitOps root.

## Behavior

The command:

1. creates the `argocd` namespace, GitHub OAuth and webhook Secrets, and the
   distinct Vault and Grafana Dex client Secrets;
1. creates the `monitoring` namespace and its Grafana Dex client and stable
   administrator Secrets;
1. renders the pinned Argo CD chart and applies it with the same server-side
   field manager used by Argo CD;
1. waits for every rendered chart Job and Argo CD deployment, then refreshes
   the ApplicationSet controller;
1. creates the cert-manager and ExternalDNS namespaces and their Cloudflare
   Secrets, plus the ZeroSSL EAB Secret;
1. applies [`argocd/root-application.yaml`](../../../argocd/root-application.yaml);
   and
1. removes `argocd-initial-admin-secret`.

Secrets come from encrypted `secrets/bootstrap.yaml` and are passed through
standard input rather than committed to values files. The root Application then
reconciles the Argo CD chart, Cilium, Gateway API, and the remaining desired
state from Git.

## Usage

```bash
k install argocd
```

## Prerequisites

- `secrets/bootstrap.yaml` is decryptable and contains real values for
  `ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`, `ARGOCD_GITHUB_WEBHOOK_SECRET`,
  `CLOUDFLARE_API_TOKEN`, `GRAFANA_ADMIN_PASSWORD`,
  `GRAFANA_OIDC_CLIENT_SECRET`, `VAULT_OIDC_CLIENT_SECRET`, and
  `ZEROSSL_EAB_HMAC_KEY`.
- Cilium is installed and the cluster is reachable.
- The pinned Argo CD Helm repository is reachable.
- [`argocd/values.yaml`](../../../argocd/values.yaml) and
  [`argocd/root-application.yaml`](../../../argocd/root-application.yaml) exist.

This is a live operation with no confirmation prompt. After bootstrap, change
desired state in Git instead of rerunning this command for ordinary upgrades.
Use `k initialize monitoring` to materialize or rotate only the Grafana OIDC
Secrets on an existing cluster.
