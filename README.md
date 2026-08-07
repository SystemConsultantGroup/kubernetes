# SCG Kubernetes

Configuration and tooling for the single `scg` cluster: Talos, Cilium, Argo CD, and SOPS-managed secrets.

## Bootstrap

```bash
nix develop
k secrets check
k install
```

`state.yaml` selects the endpoint, nodes, and component versions. Every declared node needs a matching `patches/<node>.yaml`.

> [!WARNING]
> `k install` configures the declared machines. Confirm `state.yaml` and the disk selectors in `patches/` before running it.

## Secrets

Create an age identity and send its printed recipient to an existing operator:

```bash
k secrets recipients me
```

The existing operator grants access with:

```bash
k secrets recipients add <person-device> <age1...>
```

Validate or edit encrypted values:

```bash
k secrets check
k secrets edit bootstrap
k secrets edit talos
```

`bootstrap` must contain `ARGOCD_GITHUB_OAUTH_CLIENT_SECRET` and `CLOUDFLARE_API_TOKEN`. The Cloudflare token needs Zone Read and DNS Edit access to `scg.sh`. Recipient aliases are public in `secrets/recipients.yaml`; secret values remain SOPS-encrypted.

## Deployments

Argo CD follows `main` and discovers:

- shared cluster components from `argocd/platform/*/meta.yaml`
- applications from directories under `applications/`

An application directory is also its namespace. Add a Kustomization, push to `main`, and Argo CD creates and reconciles it.

Bootstrap-only Argo CD configuration lives in `argocd/bootstrap/`; reconcile it explicitly after changing it:

```bash
k install argocd
```

Namespaces attached to the public Gateway must carry:

```yaml
gateway.scg.sh/public: "true"
```

ExternalDNS publishes `HTTPRoute.spec.hostnames` under `scg.sh` through Cloudflare. The inactive RFC2136 configuration for `scg.skku.ac.kr` is kept in `argocd/platform/external-dns-scg.skku.ac.kr/` as `*.example` files.

## Operations

Apply Talos patch changes:

```bash
k apply
```

Change a version in `state.yaml`, then run its upgrade:

```bash
k upgrade <talos|kubernetes|cilium|argocd>
```

Reset a node:

```bash
k reset [--yes] [node]
```

> [!CAUTION]
> Reset wipes Talos `STATE` and `EPHEMERAL` data.

For local Argo CD access or command discovery:

```bash
k forward argocd
k --help
k <command> --help
```
