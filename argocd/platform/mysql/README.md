# MySQL platform

This Argo CD Application owns the PXC cluster's namespaced resources separately
from the Percona operator. It starts with the Vault integration required to
materialize PXC system-user credentials without storing values in Git.

The `mysql` Vault role is bound only to the `vault-auth` ServiceAccount in this
namespace and can read only `kv/data/platform/mysql/*`. The namespaced
SecretStore extracts `platform/mysql/pxc-system-users` into the
`pxc-system-users` Kubernetes Secret.

The system-user value must contain these keys:

- `root`;
- `xtrabackup`;
- `monitor`;
- `proxyadmin`;
- `operator`; and
- `replication`.

The generated Secret is orphaned and retained deliberately. Removing or
temporarily failing the ExternalSecret must not delete credentials used by a
running database. Rotate values through Vault and verify that the operator has
propagated them before removing an old recovery copy.

Backup and PITR credentials require a separate Vault value and ExternalSecret.
Do not add them until the onsite S3 endpoint, bucket, and credential scope are
approved. Application database users also require separate least-privilege
Secrets; applications must not use PXC system accounts.

The future `PerconaXtraDBCluster` resource belongs in `manifests/`, must
reference `pxc-system-users`, and must carry `argocd.argoproj.io/sync-options: Prune=false`. Its single-member rehearsal configuration must explicitly set
`unsafeFlags.pxcSize: true`, use `local-data`, and request only a bounded portion
of the SCC data volume.
