[한국어](README.md) | English

# Platform components

This directory defines the cluster services that support applications.
Each active component is an Argo CD `Application` assembled by
[`../kustomization.yaml`](../kustomization.yaml) and assigned to the `platform`
AppProject.

## Components

| Directory | Purpose |
| --- | --- |
| [`argocd/`](argocd/README.en.md) | Argo CD chart, namespace resources, and public route |
| [`gateway-api/`](gateway-api/README.en.md) | Upstream standard Gateway API definitions |
| [`cilium/`](cilium/README.en.md) | CNI, kube-proxy replacement, eBPF, and network policy |
| [`envoy-gateway/`](envoy-gateway/README.en.md) | Envoy Gateway controller and Gateway-specific CRDs |
| [`cert-manager/`](cert-manager/README.en.md) | ZeroSSL Cloudflare issuer and platform certificates |
| [`external-dns-scg.sh/`](external-dns-scg.sh/README.en.md) | Cloudflare records for `scg.sh` Gateway HTTPRoutes |
| [`external-secrets/`](external-secrets/README.en.md) | Synchronizes external values into namespaced Kubernetes Secrets |
| [`gateway/`](gateway/README.en.md) | Envoy public Gateway, listener policies, and `gateway-system` namespace |
| [`local-path-provisioner/`](local-path-provisioner/README.en.md) | Dynamic node-local volumes from Talos user storage |
| [`mysql/`](mysql/README.en.md) | PXC cluster resources and namespaced Vault integration |
| [`percona-operator/`](percona-operator/README.en.md) | Reconciles Percona XtraDB Cluster resources in `mysql` |
| [`reloader/`](reloader/README.en.md) | Rolls managed workloads when referenced Secrets change |
| [`vault/`](vault/README.en.md) | Vault server with Raft storage and Cloudflare Worker auto-unseal |
| [`external-dns-scg.skku.ac.kr/`](external-dns-scg.skku.ac.kr/README.en.md) | Inactive RFC2136 reference configuration |

For common investigations, follow the complete controller chain:

| Symptom or task | Start here | Then check |
| --- | --- | --- |
| Public route | Gateway and HTTPRoute conditions | cert-manager, then ExternalDNS |
| Managed secret | Vault path and policy | External Secrets, then Reloader |
| Stateful local volume | StorageClass and PersistentVolume | local path provisioner, node path, and Talos volume |
| GitOps reconciliation | Generated or platform Application | AppProject permissions and root sync wave |

Active components use automated sync, pruning, and self-healing. The root uses
this reconciliation order:

| Wave | Components | Dependency intent |
| --- | --- | --- |
| 1 | Gateway API, Cilium, Envoy Gateway, External Secrets, local path provisioner | APIs, networking, Gateway controller, and storage foundations |
| 2 | Gateway, cert-manager, Percona PXC Operator, Reloader | public Gateway, certificates, and application support controllers |
| 3 | Argo CD, ExternalDNS, MySQL resources, Vault | externally routed and stateful services |

A wave starts child Application reconciliation in order; it does not wait for
one component's complete health before starting the next wave. Bootstrap
credentials are created by `k install argocd` from encrypted values. Never put
tokens in platform values files.

Vault uses the non-default `local-data` class, HTTPS at
`vault.platform.scg.sh`, and the Transit-compatible Worker at
`kms.vault.platform.scg.sh`. Initialization, recovery, and the managed secret
contract are documented in the
[Vault component README](vault/README.en.md).

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
