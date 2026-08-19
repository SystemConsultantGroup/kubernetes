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
`ZEROSSL_EAB_HMAC_KEY` in encrypted `secrets/bootstrap.yaml`, plus the Vault
Transit credentials in encrypted `secrets/vault.yaml`.
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
- every declared node has `patches/<node>.yaml`; and
- `patches/worker.yaml` and `patches/cilium.yaml` exist.

Individual subcommands document additional requirements. `state.yaml` is the
source of truth for all component versions.

## Behavior

The full command runs the subcommands in the order above and stops at the first
failure.
Individual steps can be rerun after a partial failure.
These are live cluster-changing operations and have no confirmation prompt.
