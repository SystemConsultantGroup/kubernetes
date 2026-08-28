[한국어](README.md) | English

# MySQL platform

This Argo CD Application owns the PXC database clusters in the `mysql`
namespace separately from the namespaced Percona operator. The operator watches
only this namespace. Add each cluster as a named manifest under
`manifests/clusters/` and include it from `manifests/kustomization.yaml`.

## Clusters

| Cluster | Purpose | PXC | XtraBackup | Service |
| --- | --- | --- | --- | --- |
| `central` | Migration target for the database historically called 신 통합DB | `8.0.45-36.1` | `8.0.35-35.1` | `central-haproxy.mysql` |
| `alumni` | New database for the alumni project | `8.4.8-8.1` | `8.4.0-5.1` | `alumni-haproxy.mysql` |

`central` is the target for the source historically called 신 통합DB. Whether
the separate 구 통합 DB will also be migrated remains undecided; if it is, give
that migration its own reviewed identity rather than overloading `central`.

The image versions and digests are pinned. Alumni uses the PXC 8.4 and
XtraBackup versions certified with Percona Operator 1.20.0. Automatic version
application is disabled so upgrades remain separate reviewed GitOps changes.

## Credentials and lifecycle safety

Each cluster has a unique `spec.secretsName`. When its Secret is absent, the
operator creates it with generated credentials and manages the PXC system users.
Do not declaratively create the same Secret or let another controller compete
for its ownership. Never commit or print credential values, and use Percona's
supported password-rotation procedure rather than replacing the complete
Secret.

Every cluster CR carries both protections:

```yaml
argocd.argoproj.io/sync-options: Prune=false,Delete=false
```

Removing a manifest or deleting the Argo CD Application must not automatically
delete a database cluster. Decommissioning requires a separate reviewed
procedure that freezes clients, verifies recovery material, removes these
protections deliberately, and handles retained volumes explicitly.

## Topology and resources

Both clusters currently run two PXC members and two HAProxy instances, with
required hostname anti-affinity placing one of each on `k8s` and `e2s`. Both
size-related unsafe flags remain required. This is a transitional topology, not
high availability: both PXC members are required for Galera quorum, so losing
either member makes that cluster unavailable. Do not perform member-failure or
unsupervised rollout tests.

The manifests retain CPU and memory requests but intentionally set no resource
limits for now. Add reviewed limits after measuring the real workloads. Each PXC
member requests a retained 200 GiB `local-data` claim and 16 GiB of memory with
a 12 GiB InnoDB buffer pool. The hostPath provisioner does not enforce the PVC
request as a filesystem quota, so monitor each data volume's actual use and
headroom.

`RollingUpdate` remains configured for this supervised two-member stage. After
three physical nodes and their storage are proven, scale each cluster to three,
restore `SmartUpdate`, and remove the unsafe flags only after strict placement,
SST, quorum, and readiness checks pass.

## Database and recovery settings

PXC strict mode, durable transaction-log settings, UTF-8 defaults, source
compatibility settings, and the `+09:00` timezone are explicit. DNS hostname
resolution is disabled to avoid Kubernetes reverse-lookup delays, so grants must
use `%` or address patterns instead of DNS hostnames.

Both clusters use the independent MinIO S3 API at
`https://api.minio.scg.skku.ac.kr`, with separate `pxc-central` and `pxc-alumni`
buckets. A dedicated Vault Kubernetes-auth role can read only
`kv/platform/mysql/s3`; External Secrets maps its two access-key properties into
the shared `mysql-backup-s3` Secret. The MinIO policy is limited to those two
buckets and excludes object deletion, Governance bypass, KMS, and administrative
access.

The buckets use versioning, 14-day Governance retention, and lifecycle expiry.
Operator-side remote deletion retention remains disabled because deleting a
required full backup or binlog can break PITR. The on-demand full backups have
been restored successfully into disposable PXC 8.0 and 8.4 clusters. The live
clusters now run staggered daily full backups (central at 02:00 and alumni at
03:00) and upload PITR binlogs every 60 seconds. The cron schedules use the
Operator's configured timezone; verify the first scheduled runs explicitly.
MinIO is the only backup tier, so loss of the MinIO system remains an accepted
residual risk.

The first scheduled backups and PITR upload health are operational gates, not
proof of recoverability by themselves. Confirm each scheduled backup reaches
`Succeeded`, inspect PITR uploader errors and binlog gaps, and complete a
PITR timestamp restore before treating this as a production recovery system.
