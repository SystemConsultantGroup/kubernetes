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
| [`external-secrets/`](external-secrets/) | Synchronizes external values into namespaced Kubernetes Secrets |
| [`gateway/`](gateway/) | Cilium public Gateway and `gateway-system` namespace |
| [`local-path-provisioner/`](local-path-provisioner/) | Dynamic node-local volumes from Talos user storage |
| [`reloader/`](reloader/) | Rolls managed workloads when referenced Secrets change |
| [`vault/`](vault/) | Vault server with Raft storage and Cloudflare Worker auto-unseal |
| [`external-dns-scg.skku.ac.kr/`](external-dns-scg.skku.ac.kr/) | Inactive RFC2136 reference configuration |

Active components use automated sync, pruning, and self-healing. Root sync
waves create foundational operators and storage first, supporting controllers
and certificates second, and externally routed services third. A wave orders
child Application reconciliation but does not replace component health checks.
Bootstrap credentials are created by `k install argocd` from encrypted values;
never put tokens in platform values files.

Vault uses the non-default `local-data` class, HTTPS at
`vault.platform.scg.sh`, and the Transit-compatible Worker at
`kms.vault.platform.scg.sh`. Initialization, recovery, and the managed secret
contract are documented in the [Vault component README](vault/README.md).

## Public routing

The public Gateway accepts routes from namespaces labeled:

```yaml
gateway.scg.sh/public: "true"
```

The active ExternalDNS instance observes Gateway HTTPRoutes and manages `scg.sh`
records through Cloudflare.
Testing and preview listeners use wildcard DNS records and certificates from
ExternalDNS and cert-manager. Production domains marked external are excluded
from this DNS and certificate flow.

## Changes

Keep each component's Application here and include it in
[`../kustomization.yaml`](../kustomization.yaml).
Select the narrowest suitable AppProject permissions and review sync waves,
namespaces, credentials, and cluster-scoped resources before merging.

Files under `external-dns-scg.skku.ac.kr/` end in `.example` and are inactive
reference configuration until a complete DNS and secret setup is approved.
