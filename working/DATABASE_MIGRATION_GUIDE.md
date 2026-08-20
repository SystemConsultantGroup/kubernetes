# Database migration guide

This guide is the concise migration path proven by the SCC rehearsal. It covers
preparation, the final maintenance-window import, validation, cutover, and the
transition from one PXC member to three. Detailed reasoning and measurements are
in [DATABASE.md](DATABASE.md). Sensitive endpoints, inventories, and artifact
locations remain in the ignored appendix.

## Current stop point

The platform currently has:

- Percona PXC Operator 1.20.0;
- one explicitly unsafe PXC 8.0.45 member and one HAProxy on SCC;
- a retained local claim on the Talos data volume;
- Vault-backed PXC system credentials;
- enforced PXC strict mode and TLS; and
- the transformed, non-authoritative rehearsal data.

The rehearsal imported 41 schemas, 551 InnoDB tables, and 15,724,817 rows in
219 seconds. It is not ready for production cutover because application tests,
an authoritative source dump, onsite restore testing, offsite backup, PITR, and
a second full import remain incomplete.

Do not upgrade to PXC 8.4 during this migration. Keep that as a later change.

## Safety rules

- Make desired-state changes through Git and Argo CD, not direct edits to
  Argo-managed resources.
- Never put database, application, or object-store credentials in Git, logs, or
  migration notes.
- Do not erase E1S until post-cutover PXC backups have been verified and at
  least one restore has succeeded.
- Do not treat the one-member PXC topology as highly available.
- Do not rely on the 250 GiB PVC request as a quota; hostPath can consume the
  full data filesystem.
- Stop immediately if source writes cannot be frozen, an artifact checksum
  fails, the transformation inventory changes, or validation differs from the
  approved baseline.

## Before the maintenance window

Complete all of these first:

1. Repeat the transformed import at least once from an empty rehearsal target.
1. Onboard representative applications and Keycloak and test them against the
   transformed schema.
1. Prepare deterministic application users and grants. Do not use PXC system
   accounts, and do not use DNS hostnames in grants because
   `skip_name_resolve=ON`.
1. Configure onsite S3-compatible backup storage with scoped credentials from
   Vault.
1. Configure PITR and ensure binlogs reach the onsite target.
1. Copy at least one complete recovery set to independent offsite storage.
1. Delete a disposable target and restore it only from object storage.
1. Record source table counts and selected deterministic logical checksums.
1. Pre-pull all required images and confirm SCC storage headroom.
1. Prepare application maintenance mode, connection changes, smoke tests, and
   rollback ownership.

A successful rehearsal import alone is not a cutover authorization.

## Prepare the final source artifact

The rehearsal dump is not authoritative because its account could not lock
active MyISAM tables. For the final artifact:

1. Put every writing application into maintenance mode.
1. Block source writes and confirm no writing transaction remains.
1. Use an account permitted to hold the required global read lock for the whole
   dump so MyISAM and InnoDB represent one frozen source state.
1. Dump all approved application schemas, including triggers, routines, and
   events even if the audit found none.
1. Exclude MySQL system schemas, users, grants, and GTID state.
1. Compress the stream with Zstandard.
1. Calculate SHA-256 checksums and write immutable metadata containing start and
   finish times, source version, schema count, and dump options.
1. Copy the untouched artifact and metadata to onsite and offsite object
   storage before transforming it.

Do not continue if writes resumed during the dump or checksum verification
fails.

## Transform for PXC

Run the audited streaming transform against a copy, never the untouched final
artifact. It must fail closed unless it finds the approved inventory.

The proven transform performs exactly these operations:

1. Change every audited `ENGINE=MyISAM` definition to `ENGINE=InnoDB`.
1. Add an explicit invisible unsigned auto-increment primary-key column to each
   audited PK-less table.
1. Remove dump-time `LOCK TABLES` and `UNLOCK TABLES` statements, which PXC
   strict mode rejects.
1. Reject any unexpected MyISAM table, existing migration-column name, primary
   key, missing table, or changed lock count.
1. Compress and checksum the transformed result independently.

The rehearsal expected 34 engine conversions, 13 primary-key additions, and 551
lock pairs. Re-audit the final source and review any changed count instead of
blindly updating those expectations.

## Reset the rehearsal target

The current PXC data is disposable rehearsal data, but its retained volume is
not automatically erased by deleting a claim or custom resource.

Before the final import:

1. Preserve the rehearsal logs, row counts, checksums, and timings.
1. Confirm the final source artifact exists in both required storage tiers.
1. Use a reviewed database reset procedure that leaves Vault and unrelated
   retained claims untouched.
1. Confirm the target contains zero application schemas.
1. Confirm PXC is Primary and ready, HAProxy is ready, TLS is valid, and the
   claim path is on the Talos data volume.

Do not casually delete the PXC custom resource or retained PV.

## Import

Stream the verified transformed artifact through the internal HAProxy service
with client output captured to a restricted, ignored log.

During import:

- keep PXC strict mode enforcing;
- keep automatic version upgrades disabled;
- keep source applications in maintenance mode;
- watch PXC, HAProxy, claim usage, node storage, and operator events; and
- abort on the first SQL or transport error.

The rehearsal import took 219 seconds and produced no client errors. Treat that
only as a planning baseline; final duration depends on source growth and storage
conditions.

## Validate the target

All checks must pass before application cutover:

1. Compare the approved schema count and base-table count.
1. Require every application table to use InnoDB.
1. Require every writable table to have a primary key.
1. Confirm every explicit migration key is invisible and populated.
1. Run `mysqlcheck` across the imported databases.
1. Capture exact row counts for every table.
1. Compare selected deterministic logical checksums with the frozen source.
1. Confirm PXC strict mode is `ENFORCING`.
1. Confirm `sync_binlog=1` and `innodb_flush_log_at_trx_commit=1`.
1. Confirm Galera reports Primary, ready, and cluster size one.
1. Confirm HAProxy connectivity over TLS-aware application clients.
1. Create the reviewed application users and grants separately from the dump.

Target `CHECKSUM TABLE` values are useful for repeat-import comparison but do
not replace logical source-to-target checksums across different storage engines.

## Test applications and recovery

Before enabling production writes:

1. Test representative read and write paths for every application family.
1. Test Keycloak startup, login, and Liquibase changelog behavior.
1. Verify invisible primary keys do not change application-visible result sets.
1. Take a fresh PXC physical backup and enable PITR uploads.
1. Delete a disposable database copy and restore it only from onsite object
   storage.
1. Verify an independent offsite copy exists and cannot be deleted immediately
   with source credentials.
1. Record backup size, restore duration, PITR object count, and every manual
   intervention.

Failure of any application or restore test blocks cutover.

## Cut over

1. Keep the source frozen and read-only.
1. Take and verify one final target backup.
1. Change application configuration to the internal HAProxy ClusterIP service.
1. Start applications while writes remain operationally controlled.
1. Run schema, authentication, read, and write smoke tests.
1. Enable normal writes on PXC only after all smoke tests pass.
1. End maintenance mode and monitor errors, latency, connections, storage, and
   backup uploads.

Once PXC accepts new writes, the old source is only a historical and forensic
fallback. Returning applications to it would lose target-side changes unless a
separate reverse-replication plan exists. Treat enabling PXC writes as the
no-return gate.

## After cutover

1. Leave E1S intact and read-only for several days.
1. Verify new full backups and PITR data in every intended tier.
1. Complete another restore test from the post-cutover backup.
1. Configure E1S hardware RAID and final disk identifiers only after backup
   verification.
1. Install Talos and its data user volume, then join E1S to Kubernetes.
1. Add E2S and E1S as independent PXC placements and scale directly from one
   member to three, never to two.
1. Remove SCC-only selectors, enforce one member and one HAProxy per hostname,
   and restore `SmartUpdate`.
1. Remove the size-related unsafe flags only after all three members are ready
   and quorum, SST, placement, and backup health are verified.
1. Schedule the PXC 8.4 upgrade as a separate project.

## Proven troubleshooting findings

- Old partition and filesystem signatures can survive RAID logical-drive
  creation; identify them before authorizing a wipe.
- HAProxy health checks can stall on Kubernetes reverse DNS. The rehearsal fixed
  this with `skip_name_resolve=ON`.
- A one-member unready cluster can prevent `SmartUpdate` from restarting its
  only member. Use `RollingUpdate` only for the one-member rehearsal and return
  to `SmartUpdate` at three members.
- A no-lock source dump can still contain import-time table-lock statements.
  Remove them in the PXC transform.
- Use repository tooling or pass the repository kubeconfig explicitly when
  composing one-off Zstandard and `kubectl` pipelines.
