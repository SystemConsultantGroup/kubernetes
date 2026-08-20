# install

Bootstraps the cluster in order: Kubernetes, Cilium, Argo CD, then Vault.

## Usage

```bash
k install
k install <command>
```

Running `k install` with no subcommand performs the complete bootstrap.
It requires real values for `ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`,
`ARGOCD_GITHUB_WEBHOOK_SECRET`, `CLOUDFLARE_API_TOKEN`, and
`VAULT_OIDC_CLIENT_SECRET`, and `ZEROSSL_EAB_HMAC_KEY` in encrypted
`secrets/bootstrap.yaml`, plus the Vault Transit credentials in encrypted
`secrets/vault.yaml`.
Set them with `k secrets edit bootstrap` and `k secrets edit vault`.

## Subcommands

- `kubernetes` installs Talos configuration, Kubernetes, etcd, and kubeconfig.
- `gateway-api` installs the pinned Gateway API standard CRDs.
- `cilium` installs Gateway API support and the pinned Cilium release.
- `argocd` installs Argo CD and bootstraps the GitOps root.
- `vault` installs and initializes Vault, replacing its encrypted recovery
  output after a destructive reset.

## Prerequisites

For the full bootstrap:

- every encrypted file under `secrets/` is decryptable with the local age key;
- every declared node has `patches/<node>.yaml`;
- `patches/worker.yaml` and `patches/cilium.yaml` exist; and
- the configured Transit-compatible Worker responds successfully at
  `https://kms.vault.platform.scg.sh/healthz`.

Individual subcommands document additional requirements. `state.yaml` is the
source of truth for all component versions.

## Behavior

Before changing the cluster, the full command validates all bootstrap and Vault
secret values, Talos inputs, and Worker health. It then runs the subcommands in
the order above and stops at the first failure.
Individual steps can be rerun after a partial failure.
These are live cluster-changing operations and have no confirmation prompt.
