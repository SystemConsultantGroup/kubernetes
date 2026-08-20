# MySQL platform

This Argo CD Application owns the PXC cluster's namespaced resources separately
from the Percona operator. The Percona operator is authoritative for PXC
system-user credentials; Vault and External Secrets are not database bootstrap
dependencies.

The cluster fixes `spec.secretsName` as `pxc-system-users`. When that Secret is
absent, the operator creates it with generated credentials and manages the PXC
system users. Do not declaratively create the same Secret or introduce another
controller that competes for its ownership.

Treat `pxc-system-users` as sensitive database state. Never commit or print its
values. Preserve it through an approved encrypted backup workflow before moving
or restoring existing database data, and use Percona's supported password
rotation procedure rather than replacing the complete Secret.

Backup and PITR credentials require a separate Secret. Do not add them until the
onsite S3 endpoint, bucket, and credential scope are approved. Application
database users also require separate least-privilege Secrets; applications must
not use PXC system accounts.

The `mysql` PerconaXtraDBCluster starts as an explicitly unsafe rehearsal with
one PXC member and one HAProxy on SCC. It uses PXC 8.0.45, references
`pxc-system-users`, and carries `argocd.argoproj.io/sync-options: Prune=false`.
The database requests a retained 250 GiB `local-data` claim, 16 GiB of memory,
and a 12 GiB InnoDB buffer pool. Local hostPath provisioning does not enforce
the 250 GiB request as a filesystem quota, so storage monitoring must protect
headroom on the shared data volume.

The single-member and single-proxy sizes require both `unsafeFlags.pxcSize` and
`unsafeFlags.proxySize`. Do not treat this topology as highly available. The
rehearsal uses `RollingUpdate` because `SmartUpdate` cannot safely progress a
restart without another ready member. Before production cutover, prove backup
restoration and offsite replication. After all three physical nodes are ready,
remove the SCC-only selectors, set both sizes to three, restore `SmartUpdate`,
and verify strict hostname anti-affinity before removing either unsafe flag.

PXC strict mode, durable transaction-log settings, source character settings,
and the source timezone are explicit in the custom MySQL configuration. DNS
hostname resolution is disabled to avoid Kubernetes reverse-lookup delays, so
user grants must use `%` or address patterns instead of DNS hostnames. Upgrade
checks are disabled so database version changes remain separate reviewed GitOps
operations.
