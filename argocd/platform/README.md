# Platform components

This directory defines the cluster services that support applications.
Each active component is an Argo CD `Application` assembled by
[`../kustomization.yaml`](../kustomization.yaml) and assigned to the `platform`
AppProject.

## Components

| Directory | Purpose |
| --- | --- |
| [`argocd/`](argocd/) | Argo CD namespace resources and its public route |
| [`cert-manager/`](cert-manager/) | ZeroSSL Cloudflare issuer and platform certificates |
| [`external-dns-scg.sh/`](external-dns-scg.sh/) | Cloudflare records for `scg.sh` Gateway HTTPRoutes |
| [`gateway/`](gateway/) | Cilium public Gateway and `gateway-system` namespace |
| [`external-dns-scg.skku.ac.kr/`](external-dns-scg.skku.ac.kr/) | Inactive RFC2136 reference configuration |

Active components use automated sync, pruning, and self-healing.
Bootstrap credentials are created by `k install argocd` from encrypted values;
never put tokens in platform values files.

## Public routing

The public Gateway accepts routes from namespaces labeled:

```yaml
gateway.scg.sh/public: "true"
```

The active ExternalDNS instance observes Gateway HTTPRoutes and manages `scg.sh`
records through Cloudflare.
Testing and preview listeners use wildcard certificates from cert-manager.
Production domains marked external are excluded from this DNS and certificate
flow.

## Changes

Keep each component's Application here and include it in
[`../kustomization.yaml`](../kustomization.yaml).
Select the narrowest suitable AppProject permissions and review sync waves,
namespaces, credentials, and cluster-scoped resources before merging.

Files under `external-dns-scg.skku.ac.kr/` end in `.example` and are inactive
reference configuration until a complete DNS and secret setup is approved.
