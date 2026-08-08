# install

Bootstraps the cluster end to end: Kubernetes, Cilium, then Argo CD.

## Description

Runs `k install kubernetes`, `k install cilium` and `k install argocd` in
order. Fails fast unless the sops-encrypted `secrets/bootstrap.yaml` contains
real values for `ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`, `CLOUDFLARE_API_TOKEN`
and `ZEROSSL_EAB_HMAC_KEY` (set them with `k secrets edit bootstrap`).

## Prerequisites

- `secrets/talos.yaml` and `secrets/bootstrap.yaml` are sops-encrypted and decodable with your age key.
- `patches/<node>.yaml` exists for every node in state.yaml, plus `patches/worker.yaml` and `patches/cilium.yaml`.
- state.yaml pins the versions used by each subcommand.

## Usage

```
k install
k install <command>
```

## Subcommands

- `argocd` — installs Argo CD with GitHub OAuth and bootstraps the cluster GitOps configuration
- `cilium` — installs the pinned Cilium release with kubeProxyReplacement and the gateway API
- `gateway-api` — installs the pinned Kubernetes Gateway API standard release
- `kubernetes` — installs the Kubernetes cluster on the Talos nodes: generate configs, apply, bootstrap etcd, wait, and write a kubeconfig

## Notes

- `k install` with no arguments runs the full bootstrap; individual steps can be re-run via the subcommands.
- Subcommands are idempotent, so the full bootstrap can be re-run after a partial failure.
