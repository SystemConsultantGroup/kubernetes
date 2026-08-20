# Vault activation follow-up

## Status

The base Vault platform is active and healthy:

- Vault is initialized and auto-unseals through the external KMS Worker;
- Raft and audit volumes use retained, node-local `local-data` claims;
- KV v2, Kubernetes authentication, GitHub OIDC, and file auditing are enabled;
- the initial root token is revoked and removed from the encrypted recovery file;
- managed SecretStores and ExternalSecrets are enabled centrally; and
- the `example` application uses non-sensitive values to verify production,
  testing, and preview layering.

External Secrets and Reloader have been verified for Secret creation, update,
deletion, recreation, and the resulting Deployment rollouts. Application
metadata does not contain Vault configuration.

The current storage choice is intentionally rebuildable. `local-data` resides at
`/var/lib/local-data` on Talos `EPHEMERAL`; `k reset` therefore removes Vault
Raft and audit data. A rebuild initializes empty Vault storage and replaces
`secrets/vault-recovery.yaml`. No Raft snapshot or restore workflow exists.

## Remaining work

1. Seed or migrate real application values into their generated
   `kv/applications/...` paths without exposing plaintext in logs, shell history,
   documentation, or Git.
1. Verify each production path and workload identity before writing production
   values.
1. Decide whether to enable Worker mTLS as an additional factor.
1. Rehearse recovery-share root generation and document the approved
   break-glass ceremony without recording recovery material.

Application onboarding does not require a Vault policy or role change. Custom
Kustomize applications do not receive the managed secret integration.

## Migration convention

Legacy paths such as:

```text
kv/data/alumni-dev-be-secret
kv/data/alumni-prod-be-secret
```

move to:

```text
kv/data/applications/alumni/testing/be
kv/data/applications/alumni/production/be
```

Legacy properties such as `minio-endpoint` become portable environment keys such
as `MINIO_ENDPOINT`. Production, testing, and preview maps should expose the
same key names even when values differ. Remove a legacy source only after the
generated Kubernetes Secret and workload rollout have been verified.

## Durable documentation

The lasting contracts and procedures now live with their components:

- [`../argocd/platform/vault/README.md`](../argocd/platform/vault/README.md)
  covers storage, initialization, operator access, application paths, and
  recovery boundaries.
- [`../argocd/charts/application/README.md`](../argocd/charts/application/README.md)
  covers generated ExternalSecrets, layering, environment precedence, and
  rollout behavior.
- [`../workers/kms/README.md`](../workers/kms/README.md) covers Worker security,
  deployment, validation, and key rotation.
- [`../argocd/platform/local-path-provisioner/README.md`](../argocd/platform/local-path-provisioner/README.md)
  covers the current node-local storage durability boundary.
