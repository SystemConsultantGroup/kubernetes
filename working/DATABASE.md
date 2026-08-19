# Database platform planning transcript

This is a condensed transcript of the database-platform discussion. It rephrases the conversation for clarity while retaining the observations, rejected approaches, trade-offs, formulas, and current plan.

Sensitive endpoints, access instructions, physical-location details, schema names, table names, and local artifact paths are kept in the intentionally untracked [sensitive appendix](ignored/DATABASE.md). The appendix is ignored by Git through `working/ignored/`.

## Starting situation

The Talos cluster initially had one active node, SCC, and no application data that needed preservation. E2S can be added relatively soon. E1S currently runs the standalone MySQL server that must be migrated before E1S can be wiped and joined to Kubernetes.

The intended minimum disk layout for every Kubernetes node is:

- two 500 GB SSDs in RAID 1 for Talos and Kubernetes ephemeral storage;
- two 2 TB SSDs in RAID 1 for user data;
- an equivalent or better four-disk RAID 10 arrangement is acceptable for the data tier.

The original migration concept was:

1. Experiment on SCC.
1. Add E2S and temporarily operate two Kubernetes nodes.
1. Freeze the existing database.
1. Dump and protect its state.
1. Restore it into an operator-managed MySQL service.
1. Validate the restored service.
1. Redirect applications.
1. Wipe E1S and join it to Kubernetes.
1. Replicate the database onto E1S.
1. Resume normal operation.

Safety is more important than performance, but the project cannot fund an ideal high-availability migration. A planned outage of as much as one day is acceptable, although a shorter outage is preferred. The objective is a substantial improvement over the current system, especially prevention of total loss, rather than elimination of every availability risk.

## Repository and cluster inspection

The repository currently enables only SCC in `state.yaml`. E1S and E2S have node patches but are not active. The cluster permits workloads on control-plane nodes.

At the initial inspection, SCC reported:

- 96 CPU cores;
- approximately 535 GiB of memory;
- approximately 445 GiB of Kubernetes ephemeral capacity;
- no StorageClass;
- no persistent volumes or claims.

Talos initially saw four independent physical disks:

- two approximately 1.9 TB SSDs;
- two approximately 480 GB SSDs.

The SCC hardware RAID conversion and Talos reinstallation are now complete. The controller presents two logical volumes:

- a 480 GB system RAID volume containing Talos `STATE` and `EPHEMERAL`;
- a 1.9 TB data RAID volume intended for the `data` Talos user volume and database persistent volumes.

The current SCC patch selects both logical volumes by their controller-provided WWIDs. The `data` user-volume configuration is present but not ready: Talos reports that the selected data volume has insufficient free space for the requested volume, and no `/var/mnt/data` mount exists. The existing `local-data` StorageClass is nevertheless deployed and has bound local claims on `/var/lib/local-data` within `EPHEMERAL`; it is not yet suitable as the database data tier.

Hardware RAID is preferred to Talos software RAID because the controllers support hot-swap and because the repository currently pins Talos 1.13.7. The RAID controller may expose new WWIDs, so each node patch must be updated after its arrays are configured. SCC has been updated; E1S and E2S still require their final controller WWIDs before activation.

Controller operating requirements include:

- enable write-back only when protected by battery-backed or flash-backed cache;
- otherwise use write-through;
- monitor array degradation, media errors, rebuilds, and cache or battery state;
- use controller or BMC monitoring because ordinary filesystem metrics are insufficient.

## Storage design

The initial recommendation is node-local persistent storage rather than Longhorn, Mayastor, or another replicated block layer.

PXC already maintains three database copies in the final topology. Adding replicated block storage would duplicate replication, consume more network and capacity, and introduce additional correlated failure behavior.

The local-storage design must provide:

- a ready Talos user volume on the data RAID logical volume;
- a small local-volume provisioner using that volume for database claims;
- a StorageClass using `WaitForFirstConsumer`;
- a `Retain` reclaim policy;
- strict hostname anti-affinity for final PXC placement;
- one PXC member per physical node.

The first three items are only partially complete on SCC. `local-data` already has the required binding and reclaim behavior, but its current `/var/lib/local-data` path belongs to `EPHEMERAL`. Before a PXC claim is created, resolve the failed `data` user volume, verify that it is mounted at `/var/mnt/data`, and move the provisioner path there. Existing local claims must be preserved or deliberately migrated before changing their provisioning path.

Local PV consequences are accepted:

- a PVC cannot transparently move away from a failed machine;
- PXC provides service continuity through the surviving database members;
- permanent node replacement requires recreating that member's local PVC and rebuilding it through SST;
- storage must retain headroom for SST, temporary files, and operational recovery.

The database is currently small, so a 250–500 GiB initial allocation is already generous. The full data RAID should not be allocated to one PVC.

## Rehearsal after platform storage setup

SCC now runs from hardware RAID and has active local platform claims, so it is no longer a disposable node. The local-volume provisioner is deployed, but the data RAID user volume is not ready because Talos finds insufficient free space on its selected logical volume. Resolve that condition without erasing data of uncertain value, then verify the `data` volume and its `/var/mnt/data` mount before the database rehearsal.

The rehearsal should:

1. Verify the ready Talos `data` user volume and configure the provisioner to use it for database claims.
1. Preserve or deliberately migrate existing local claims before changing the provisioner path.
1. Install the Percona PXC Operator.
1. Deploy a single PXC member with unsafe configuration explicitly enabled.
1. Load the experimental logical dump described below.
1. Convert every MyISAM table to InnoDB in the target copy.
1. Add primary keys to every affected table.
1. Run PXC strict mode.
1. Test representative applications and Keycloak.
1. Configure backups and PITR against onsite S3-compatible storage.
1. Delete the test database and restore it only from object storage.
1. Record timings and every manual intervention.

The PXC rehearsal data may be disposable, but existing SCC platform data is not. SCC should not be wiped again as part of this sequence.

## Operator choice

The preferred database operator is Percona Operator for MySQL based on Percona XtraDB Cluster rather than the newer Percona Server Operator.

Reasons include:

- PXC Operator is the more mature option for this use case;
- it provides synchronous Galera replication;
- it has a documented external-database migration path;
- the Percona Server Operator's asynchronous mode is less mature;
- the final three-node topology naturally maps one PXC member to each machine.

The proposed initial versions are:

- Percona PXC Operator 1.20.0;
- PXC 8.0.45 rather than an immediate move to 8.4.

Staying on the 8.0 series minimizes the first migration step from MySQL 8.0.36. A later version upgrade should be handled separately after the platform is stable.

The final service should contain:

- three PXC members;
- one member on each physical node;
- three HAProxy instances distributed across nodes;
- an internal ClusterIP endpoint for applications;
- no public HTTP Gateway exposure for MySQL;
- restricted temporary TCP access only if an application must remain outside Kubernetes during migration.

## Quorum and the temporary topology

PXC should not run as a two-member cluster. Two members do not provide safe majority behavior. During experimentation, PXC should remain size 1 and then scale directly to size 3 after all physical nodes exist.

A two-control-plane-node Kubernetes cluster is also not highly available: both etcd members are required for quorum. Existing workloads might continue temporarily if the API is unavailable, but the control plane and operators cannot reconcile.

A temporary independent third node was considered. Its benefits would be:

- PXC quorum during E1S conversion;
- another current copy of the data after E1S is erased;
- continued service if one migration node fails.

It is not currently available. A VM on SCC or E1S would not constitute an independent failure domain and would offer limited value. The agreed compromise is not to delay migration while waiting for a temporary node.

The accepted transitional risk is:

- run one PXC member on SCC only after its data RAID user volume is ready;
- SCC is already protected by hardware RAID before production cutover;
- continuously copy backups and binlogs off SCC;
- accept that SCC loss during the short transition causes downtime and restore work rather than transparent failover;
- join E1S and scale directly from one to three members as soon as validation and backups permit.

The three permanent nodes have different reliability characteristics. SCC is the strongest failure domain; E2S and E1S are weaker in different ways. Exact physical and power details are in the sensitive appendix. The three-node cluster protects against one machine's loss but not every university-wide correlated event.

One gigabit networking is sufficient for the observed workload. The current data set is small, and recent binlog generation is modest. SST should be short. Galera will be more sensitive to round-trip latency and the slowest storage member than to current bandwidth consumption.

## Existing MySQL inspection

Only read-only operations were performed against the existing server.

The source is:

- MySQL 8.0.36;
- using TLS for the audit connection;
- configured with GTID enabled;
- configured with GTID consistency enabled;
- using row-based binary logging;
- using 16 KiB InnoDB pages;
- using case-sensitive table names;
- using `utf8mb4` and `utf8mb4_general_ci`;
- using database timezone `+09:00`;
- configured with `innodb_flush_log_at_trx_commit=1`;
- configured with `sync_binlog=0`.

The existing data directory occupied approximately 2.1 GB, including about 1.9 GB of binary logs. Allocated application table data was approximately 1.2 GiB.

The source filesystem is an LVM volume spanning multiple physical disks without visible mirroring. That makes creating independent backups urgent. Exact host, filesystem, and access details are in the sensitive appendix.

Runtime observations included:

- configured maximum connections: 8,000;
- observed peak connections: 137;
- connections at inspection time: 128;
- running connections at inspection time: 2;
- only six slow queries over the long server uptime.

The target should not copy the current oversized settings blindly. An initial target configuration should be tested around:

- 300–500 maximum connections;
- an 8–16 GiB InnoDB buffer pool;
- `sync_binlog=1`;
- `innodb_flush_log_at_trx_commit=1`.

Initial compatibility inspection found:

- 41 non-system schemas, including empty schemas;
- 517 InnoDB tables;
- 34 MyISAM tables;
- 13 tables without primary keys;
- no views;
- no triggers;
- no stored routines;
- no scheduled events;
- no partitioned tables;
- no observed XA or `GET_LOCK()` use.

Most stored data is in MyISAM tables. The largest is an active production log table of approximately 786 MiB and 13.6 million rows. Two additional production MyISAM log tables are approximately 15 MiB each. A deprecated schema contains 28 small MyISAM tables.

The only InnoDB table without a primary key is Keycloak's Liquibase changelog table, which is actively read and has received writes. The other PK-less tables are MyISAM.

PXC strict mode cannot safely operate this schema unchanged. Required remediation is:

- transform all MyISAM definitions to InnoDB;
- provide primary keys for all 13 PK-less tables;
- test application behavior after conversion;
- keep PXC strict mode enabled in the final service.

Explicit primary keys are preferred. Explicit invisible auto-increment primary keys may be suitable where application-visible schema changes are risky, but they must be tested across all PXC members. Reliance on dynamically generated invisible keys was rejected as a default because configuration or replication differences can produce schema divergence.

`LOCK TABLES` statements were present in performance history, but their timestamps aligned across many schemas and appeared to come from historical backup or import operations. There was no evidence that applications currently depend on advisory locks or XA. Application tests are still required.

Detailed schema and table names are in the sensitive appendix.

## Migration strategy evolution

The first low-downtime suggestion was:

1. Take an initial online backup.
1. Restore it to PXC.
1. Configure GTID asynchronous replication from the source.
1. Let PXC catch up.
1. briefly block source writes;
1. verify zero lag;
1. promote PXC and redirect applications.

The MyISAM audit changed that recommendation. A single-transaction dump is not consistent for actively changing MyISAM tables. Directly combining a MyISAM source, transformed InnoDB target, and asynchronous replication adds complexity that is unnecessary when a one-day maintenance window is affordable.

The preferred migration is now a rehearsed logical migration during maintenance.

### Preparation

Before maintenance day:

1. Complete at least two rehearsal imports.
1. Measure dump, conversion, import, and validation duration.
1. Create deterministic schema-transformation scripts.
1. Record schema, table counts, approximate sizes, and selected checksums.
1. Test applications against transformed PXC.
1. Verify restoration from onsite object storage.
1. Verify at least one backup has reached offsite object storage.
1. Pre-pull all container images.
1. Prepare application configuration changes.
1. Define validation, rollback, and no-return gates.

### Maintenance day

The planned sequence is:

1. Put applications into maintenance mode.
1. Block writes to the existing MySQL server.
1. Confirm that no write transactions remain.
1. Take a final logically and transactionally consistent dump, including proper handling of MyISAM.
1. Calculate and record checksums.
1. Upload the untouched dump to onsite and offsite object storage.
1. Transform MyISAM definitions to InnoDB.
1. Apply the rehearsed primary-key additions.
1. Load PXC on SCC.
1. Compare schemas, table counts, row counts, selected checksums, users, grants, and critical queries.
1. Take a fresh PXC backup.
1. Redirect applications to the HAProxy Service.
1. Enable writes on PXC.
1. Run smoke tests.
1. End maintenance mode.

The transfer itself should not dominate because the data set is small. Conversion of the large MyISAM table and application validation are expected to determine the outage length.

A conservative one-day budget allocates:

- one hour for freeze and final dump;
- one hour for transfer and verification;
- one hour for schema transformation;
- three hours for import;
- three hours for database validation;
- three hours for application cutover and tests;
- twelve hours of contingency and rollback time.

Rehearsal should reduce the actual duration substantially.

### After cutover

E1S should not be wiped on the same day merely to complete the topology.

Instead:

1. Leave the original E1S installation intact and read-only for several days.
1. Recognize that it becomes a historical fallback as soon as PXC accepts writes.
1. Confirm that new PXC backups reach every intended tier.
1. Complete at least one restore test from the new PXC backup.
1. Schedule E1S installation separately.
1. Configure and validate its hardware RAID.
1. Install Talos and its user-data volume.
1. Join it to Kubernetes.
1. Scale PXC directly from one to three.
1. Place the new members on E1S and E2S.
1. Validate SST, quorum, placement, and backup health.

Applications can continue running on SCC while E1S is rebuilt. Once target writes begin, returning to the old source would discard target-side changes unless reverse replication exists. The old server is therefore useful for validation and forensic recovery, not as a lossless post-cutover rollback target.

If rehearsal shows that the outage is unacceptable, the fallback low-downtime approach is to convert MyISAM and repair primary keys on the source during an earlier maintenance period, validate applications there, and then use an online InnoDB snapshot plus GTID replication. This mutates the current production database before migration and remains the second choice.

## Backup architecture

The accepted objective is economical protection against total loss, not ideal continuous availability.

The intended flow is:

1. PXC writes full backups and PITR binlogs to onsite S3-compatible storage.
1. An older but usable recovery set is replicated to independent offsite S3-compatible storage.
1. Epoch recovery sets are archived to Glacier Deep Archive for catastrophe recovery.
1. The onsite object store is expected to be replaced later by a separate Kubernetes cluster using Rook and Ceph.

The future backup cluster must remain operationally and physically independent from the application cluster. Glacier remains the protection against a correlated site failure.

### Onsite hot tier

Suggested initial policy:

- one full backup per day;
- retain 14 daily generations;
- retain continuous PITR binlogs covering the same period;
- enable bucket versioning;
- retain checksums and backup metadata;
- target an ordinary restore time below one hour after rehearsal.

### Offsite tier

Suggested initial policy:

- one full backup per week;
- retain four to eight weekly generations;
- retain every binlog needed from the oldest retained full backup through the present;
- use credentials independent from onsite administration;
- prevent source-side deletion from immediately destroying destination generations.

Because the data set is small, daily offsite full backups may be cheaper operationally than maintaining and validating long binlog chains.

### Glacier catastrophe tier

Suggested initial policy:

- one monthly full backup for one year;
- yearly full backups after that;
- optionally retain each month's following binlog chain when within-month PITR is required;
- otherwise accept up to a one-month catastrophe-tier RPO;
- package each epoch with its manifest and checksums.

An epoch should be independently interpretable as:

```text
epoch/
  manifest
  full-backup/
  binlogs/
  checksums
```

A single ancient snapshot followed by years of binlogs is rejected because one missing or corrupt segment can invalidate later recovery. Fresh periodic full backups provide shorter and more reliable recovery chains.

At least one offsite tier should provide versioning and Object Lock or equivalent immutability. Credentials used by the source should not be able to bypass retention. Deletion replication should be disabled or deliberately delayed.

Glacier Deep Archive has a 180-day minimum storage duration and adds 40 KiB of metadata per archived object. Raw PITR may create many small objects. Object count must be measured during rehearsal. If needed, catastrophe binlogs can be packaged into daily or monthly archives before transition, with a documented process to unpack them into temporary S3-compatible storage for restoration.

Restore tests should include:

- quarterly restoration from onsite storage;
- periodic restoration from offsite S3;
- at least annual restoration from Glacier;
- restoration using only documented credentials and procedures.

## Storage-usage formula

Let:

- `R` be the required recoverable period in days;
- `F` be days between full snapshots;
- `S` be the average stored size in GiB of one full snapshot;
- `B` be average stored binlog generation in GiB per day;
- `A` be an overhead and safety factor, initially 1.15.

A simple steady-state estimate is:

\[
U(R,F) \\approx A\\left(\\frac{R}{F}S + RB\\right)
\]

To guarantee the whole recovery window, retain a baseline snapshot immediately before the window:

\[
N=\\left\\lceil\\frac{R}{F}\\right\\rceil+1
\]

The binlog span must cover the retention period plus as much as one snapshot interval:

\[
L=R+F
\]

The conservative formula is:

\[
\\boxed{U(R,F)=A(NS+LB)}
\]

Equivalent pseudocode is:

```text
usage(retention_days, snapshot_interval_days) =
    overhead * (
        (ceil(retention_days / snapshot_interval_days) + 1)
        * snapshot_size
        + (retention_days + snapshot_interval_days)
        * daily_binlog_size
    )
```

For database growth, with current database size `D0`, daily growth `G`, planning horizon `H`, and compression ratio `C`:

\[
S(H)=C(D_0+GH)
\]

Then substitute `S(H)` into the conservative formula. For simple capacity planning, using the expected end-of-horizon database size for every retained snapshot is intentionally pessimistic.

If the tiers contain independent copies:

\[
U\_{total}=U\_{onsite}+U\_{offsite}+U\_{glacier}
\]

If an S3 object is transitioned from an offsite hot class into Glacier instead of copied, it should not be counted simultaneously in both classes after transition.

For Glacier object overhead:

\[
U\_{archive}=A(NS+LB)+40\\text{ KiB}\\times O
\]

where `O` is the archived object count.

## Measurements taken from the source

A read-only logical dump was created for rehearsal and measurement. Sensitive access and local path details are in the appendix.

The dump included all 41 non-system schemas and used:

- required encrypted TLS transport;
- `mysqldump` from MySQL 8.4 tooling against MySQL 8.0.36;
- one consistent transaction for InnoDB;
- no table locks;
- streaming compression with Zstandard level 6;
- no MySQL system schemas, users, or grants;
- no triggers, routines, or events, which the source audit had shown to be absent;
- no GTID state in the dump.

Measured dump results were:

- duration: 80 seconds;
- uncompressed SQL: 1,704,054,377 bytes, approximately 1.59 GiB;
- compressed dump: 89,324,638 bytes, approximately 85.2 MiB;
- compression ratio: approximately 19:1;
- SHA-256 integrity verification: successful.

The audit account has only `SELECT` and `SHOW VIEW`. It cannot obtain global or table locks. Therefore:

- InnoDB content is transactionally consistent;
- MyISAM content may span different points in time;
- the dump is suitable for experiments and schema-conversion work;
- the dump is not an authoritative production recovery backup.

No source configuration or persistent data was changed during measurement. The dump caused only read, network, and compression load.

Two consecutive source binlogs covered 72.471192 days and contained 1,955,046,905 bytes. The measured average was:

- 25.727 MiB per day;
- 0.025124 GiB per day.

Capacity planning should initially use 0.05 GiB per day to provide approximately 2× headroom.

Using compressed logical dumps, the measured-size formula is:

\[
U(R,F)=1.15\\left[\\left(\\left\\lceil\\frac{R}{F}\\right\\rceil+1\\right)0.0832+(R+F)0.0251\\right]
\]

The budget formula is:

\[
U\_{budget}(R,F)=1.15\\left[\\left(\\left\\lceil\\frac{R}{F}\\right\\rceil+1\\right)0.0832+(R+F)0.05\\right]
\]

Current-size estimates using the measured rate are:

- onsite, 14 days with daily snapshots: approximately 1.9 GiB;
- offsite, 56 days with weekly snapshots: approximately 2.7 GiB;
- Glacier, 365 days with monthly snapshots: approximately 12.8 GiB;
- total independent copies: approximately 17.4 GiB.

Using the doubled binlog planning rate:

- onsite: approximately 2.3 GiB;
- offsite: approximately 4.5 GiB;
- Glacier: approximately 24.1 GiB;
- total independent copies: approximately 30.9 GiB.

These figures apply to compressed logical SQL dumps. Percona Operator uses physical XtraBackup backups, which may be much larger. Until an operator backup is measured after the dump is imported into PXC, retain the conservative assumption of approximately 1.5 GiB per full physical snapshot.

Using 1.5 GiB snapshots, 0.05 GiB of binlogs per day, and 15% overhead gives approximately:

- onsite tier: 26.7 GiB;
- offsite tier: 19.1 GiB;
- Glacier tier: 46.9 GiB;
- total independent copies: 92.7 GiB.

The two remaining storage measurements for rehearsal are:

1. actual compressed PXC/XtraBackup object size;
1. PITR object count and size distribution over at least 24 hours.

## GitOps organization

The repository treats database infrastructure as platform infrastructure:

```text
argocd/platform/local-path-provisioner/
argocd/platform/percona-operator/
argocd/platform/mysql/
```

These are separate Argo CD Applications:

1. local storage and StorageClass, already deployed as `local-path-provisioner`;
1. operator and CRDs;
1. PXC cluster, backup schedules, and policies.

They need explicit synchronization order. The PXC custom resource should be protected from routine automated pruning, and local PV retention must be independent of the CR lifecycle. Accidental Git deletion must not cascade into database-volume deletion.

The repository does not currently provide Argo CD with a general mechanism for decrypting SOPS application secrets. Before production, choose one of:

- an External Secrets backend;
- an Argo CD SOPS integration;
- a deliberately managed bootstrap command that decrypts and applies database and backup secrets.

Plaintext credentials must not be committed to application or platform manifests.

## Current acceptance criteria

The migration is considered sufficiently safer than the existing system when:

- SCC uses hardware RAID and its PXC local PVCs reside on the ready data RAID user volume rather than `EPHEMERAL`;
- all application tables in PXC use InnoDB;
- all writable tables have primary keys;
- PXC strict mode remains enabled;
- applications pass testing against the transformed schema;
- a complete restore from onsite object storage succeeds;
- an independent offsite backup exists;
- the final source dump has verified checksums;
- E1S is not erased until post-cutover PXC backups are verified;
- final PXC placement has one member per physical node.

## Authoritative references

- [Percona PXC Operator architecture](https://docs.percona.com/percona-operator-for-xtradb-cluster/1.20.0/operator.html)
- [Moving an external database to Kubernetes](https://docs.percona.com/percona-operator-for-xtradb-cluster/1.20.0/backups-move-from-external-db.html)
- [PXC strict mode](https://docs.percona.com/percona-xtradb-cluster/8.0/strict-mode.html)
- [PXC Operator supported versions](https://docs.percona.com/percona-operator-for-xtradb-cluster/1.20.0/versions.html)
- [PXC PITR backups](https://docs.percona.com/percona-operator-for-xtradb-cluster/1.20.0/backups-pitr.html)
- [Talos local storage](https://docs.siderolabs.com/kubernetes-guides/csi/local-storage)
- [S3 Glacier storage classes](https://docs.aws.amazon.com/AmazonS3/latest/userguide/glacier-storage-classes.html)
- [S3 Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)
