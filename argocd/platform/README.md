# Platform components

This directory contains the cluster services that support applications. Each
active component is represented by an Argo CD `Application` assembled by
[`../kustomization.yaml`](../kustomization.yaml) and reconciled in the
`platform` AppProject.

## Components

| Directory | Purpose |
| --- | --- |
| [`argocd/`](argocd/) | Argo CD namespace resources and the public Argo CD route |
| [`cert-manager/`](cert-manager/) | cert-manager values, the ZeroSSL Cloudflare issuer, and platform certificates |
| [`external-dns-scg.sh/`](external-dns-scg.sh/) | Cloudflare ExternalDNS for Gateway HTTPRoutes under `scg.sh` |
| [`gateway/`](gateway/) | Cilium public Gateway and its `gateway-system` namespace |
| [`external-dns-scg.skku.ac.kr/`](external-dns-scg.skku.ac.kr/) | Inactive RFC2136 example files for a separate DNS zone |

The active components use automated sync, pruning, and self-healing. Credentials
for Cloudflare and ZeroSSL are created during `k install argocd` from encrypted
bootstrap values; do not place tokens in platform values files.

## Platform routing

The public Gateway permits routes from namespaces carrying:

```yaml
gateway.scg.sh/public: "true"
```

The active ExternalDNS instance observes Gateway HTTPRoutes and manages
`scg.sh` records through Cloudflare. The testing and preview Gateway listeners
use wildcard certificates issued by cert-manager.

## Adding or changing a component

Keep the component's Argo CD Application in this directory and add it to
[`../kustomization.yaml`](../kustomization.yaml). Select the appropriate
AppProject and source permissions in [`../projects/`](../projects/). Review
sync waves, namespaces, credentials, and cluster-scoped resources before
merging.

The `external-dns-scg.skku.ac.kr` files end in `.example` and are not active.
They are reference configuration only until a complete DNS and secret setup is
approved.
