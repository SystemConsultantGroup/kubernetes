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

The `mysql` PerconaXtraDBCluster starts as an explicitly unsafe rehearsal with
one PXC member and one HAProxy on SCC. It uses PXC 8.0.45, references
`pxc-system-users`, and carries `argocd.argoproj.io/sync-options: Prune=false`.
The database requests a retained 250 GiB `local-data` claim, 16 GiB of memory,
and a 12 GiB InnoDB buffer pool.

The single-member and single-proxy sizes require both `unsafeFlags.pxcSize` and
`unsafeFlags.proxySize`. Do not treat this topology as highly available. Before
production cutover, prove backup restoration and offsite replication. After all
three physical nodes are ready, remove the SCC-only selectors, set both sizes to
three, and verify strict hostname anti-affinity before removing either unsafe
flag.

PXC strict mode, durable transaction-log settings, source character settings,
and the source timezone are explicit in the custom MySQL configuration. DNS
hostname resolution is disabled to avoid Kubernetes reverse-lookup delays, so
user grants must use `%` or address patterns instead of DNS hostnames. Upgrade
checks are disabled so database version changes remain separate reviewed GitOps
operations.
