# Proposed database access and retention policy

## Status and scope

This document proposes how to preserve MySQL data independently of Git resource
lifecycle while managing database access as reviewed desired state. It covers:

- retention when MySQL manifests or services are removed;
- production and development data-access accounts;
- source-network restrictions; and
- privileged and emergency administration.

This is a working proposal, not a description of fully implemented behavior.
Once accepted and implemented, move the durable contracts and operating
procedures into `argocd/platform/mysql/README.md`.

## Design principles

1. Removing an object from Git must never delete database data.
2. Absence from Git is not a valid database or account decommissioning signal.
3. Service lifecycle, stored data, account policy, and credentials have
   independent lifecycles.
4. Git contains identities and privileges, but never passwords or private keys.
5. Destructive transitions require explicit desired state and review.
6. Routine administration must use an attributable identity rather than a
   shared, permanently privileged password.
7. `root` is a break-glass identity, not a routine application or operator
   account.

## Cluster and data lifecycle

A database cluster should remain represented in Git after its workload is
stopped. The intended lifecycle is:

| State | Meaning |
| --- | --- |
| `active` | PXC and HAProxy run normally. |
| `paused` | Database Pods stop, while PVCs and desired configuration remain. |
| `retired` | The serving workload may be removed after a reviewed procedure, but the cluster record, account declarations, credentials, PVCs, PVs, and recovery metadata remain. |
| `purged` | Data is destroyed only through a separate, explicitly approved procedure. |

Stopping a database should normally set `spec.pause: true` rather than delete
its manifest. Deleting a cluster file is not an accepted decommissioning
workflow because it also discards the desired account state and recovery
context.

The current repository already provides several layers of protection:

- each `PerconaXtraDBCluster` has
  `argocd.argoproj.io/sync-options: Prune=false,Delete=false`;
- the PXC resources use the ordered Pod-deletion finalizer, not a
  PVC-deletion finalizer; and
- the `local-data` StorageClass has `reclaimPolicy: Retain`.

Consequently, removing a PXC manifest during normal Argo CD reconciliation does
not prune the live PXC resource, and deleting the Argo CD Application does not
clean up a protected PXC resource. If a PXC resource is deliberately deleted,
its PVCs should remain because no `delete-pxc-pvc` finalizer is configured.
Deleting a PVC still loses its binding metadata even when its retained PV and
host data remain, so recovery can require manual rebinding.

Repository checks should reject:

- disappearance of a known database cluster without an approved retained
  cluster record;
- a PXC PVC-deletion finalizer;
- removal of `Prune=false,Delete=false` from a live or retained PXC resource;
- changing `local-data` away from `Retain`; and
- treating namespace, PVC, PV, or local-data deletion as an ordinary GitOps
  change.

These controls reduce accidental deletion; they cannot protect against manual
PV removal, erasure of the node data volume, disk loss, or cluster-wide loss.
Verified independent backups remain mandatory.

## Database catalog as desired state

Database names should be declared explicitly instead of discovered by suffix at
runtime. A future catalog may use a form similar to:

```yaml
databases:
  - name: homepage_prod
    environment: production

  - name: homepage_dev
    environment: development

  - name: alumni_prod
    environment: production

  - name: alumni_dev
    environment: development
```

Validation must require:

- a production database name to end in `_prod`;
- a development database name to end in `_dev`;
- every managed database to belong to exactly one cluster and environment; and
- database creation and removal to occur through reviewed desired state rather
  than ad hoc SQL.

The catalog can generate or validate exact database lists for account grants.
This gives the intended policy—access to every declared database in an
environment—without depending on deprecated MySQL database-name wildcard
behavior.

## Standard access accounts

### Production account

`scg_prod` may read and modify data in every declared production database. Its
normal privileges are:

```text
SELECT
INSERT
UPDATE
DELETE
```

For example, if the catalog contains `homepage_prod` and `alumni_prod`, the
effective grants should be equivalent to:

```sql
GRANT SELECT, INSERT, UPDATE, DELETE
ON `homepage_prod`.*
TO 'scg_prod'@'%';

GRANT SELECT, INSERT, UPDATE, DELETE
ON `alumni_prod`.*
TO 'scg_prod'@'%';
```

### Development account

`scg_dev` may read and modify data in every declared development database, with
the same normal DML privileges:

```sql
GRANT SELECT, INSERT, UPDATE, DELETE
ON `homepage_dev`.*
TO 'scg_dev'@'%';

GRANT SELECT, INSERT, UPDATE, DELETE
ON `alumni_dev`.*
TO 'scg_dev'@'%';
```

### Excluded privileges

The shared production and development accounts must not receive these
privileges by default:

```text
CREATE
ALTER
DROP
INDEX
TRIGGER
EVENT
GRANT OPTION
```

Schema migration must use separate accounts, such as `scg_prod_migrate` and
`scg_dev_migrate`, with only the DDL privileges required by the migration tool.
Application runtime credentials must never include migration credentials.
Additional runtime privileges such as `SHOW VIEW`, `EXECUTE`, or
`CREATE TEMPORARY TABLES` require an explicit reviewed need.

Neither `scg_prod` nor `scg_dev` may create databases. Otherwise a holder could
create a new database within its suffix class and expand the accessible data
set outside the reviewed catalog.

## Why not use suffix wildcard grants directly

MySQL can currently express suffix grants such as:

```sql
GRANT SELECT, INSERT, UPDATE, DELETE
ON `%\_prod`.*
TO 'scg_prod'@'%';

GRANT SELECT, INSERT, UPDATE, DELETE
ON `%\_dev`.*
TO 'scg_dev'@'%';
```

The underscore must be escaped because `_` is itself a MySQL wildcard. This
form is not the selected design for two reasons:

1. wildcard use in database-level grants is deprecated as of MySQL 8.0.35; and
2. Percona Operator 1.20 cannot safely represent this value in
   `spec.users[].dbs`.

For every `spec.users[].dbs` entry, the Operator first generates
`CREATE DATABASE IF NOT EXISTS <value>` and then uses the same unquoted value in
`GRANT ... ON <value>.*`. A wildcard expression is therefore not a safe
`spec.users[].dbs` value. Exact database names generated from the catalog are
required.

## Declarative account management

Percona Operator 1.20 can create application users from `spec.users`, create
listed databases, add grants, and rotate a password when its referenced Secret
changes. A generated configuration may look like:

```yaml
spec:
  users:
    - name: scg_prod
      dbs:
        - homepage_prod
        - alumni_prod
      hosts:
        - "%"
      grants:
        - SELECT
        - INSERT
        - UPDATE
        - DELETE
      withGrantOption: false
      passwordSecretRef:
        name: central-scg-prod
        key: password

    - name: scg_dev
      dbs:
        - homepage_dev
        - alumni_dev
      hosts:
        - "%"
      grants:
        - SELECT
        - INSERT
        - UPDATE
        - DELETE
      withGrantOption: false
      passwordSecretRef:
        name: central-scg-dev
        key: password
```

This mechanism is suitable for initial creation, password rotation, and grant
addition, but it is not a complete desired-state reconciler:

- removing a user from the CR does not drop the MySQL account;
- removing a host does not remove the old `user@host` account; and
- removing a grant does not revoke the existing privilege.

Account declarations must therefore use explicit lifecycle states rather than
file deletion:

| State | Required effect |
| --- | --- |
| `present` | Create the account and reconcile its approved credentials and grants. |
| `locked` | Prevent new sessions while retaining the account and audit history. |
| `absent` | Revoke and drop the account only after explicit review. |

An initial implementation may use `spec.users` for `present` and reviewed SQL
for `locked` and `absent`. If exact automatic grant removal and account deletion
become necessary, introduce a dedicated access reconciler. Such a reconciler
must default to retaining an account when its Kubernetes or Git object is
accidentally deleted; destructive behavior must require an explicit
`state: absent` transition.

Any reconciler must manage only accounts it owns, based on a reserved prefix or
a separate management registry, and must never alter Percona system users such
as `root`, `operator`, `monitor`, `xtrabackup`, `proxyadmin`, or `replication`.

## Credential storage and distribution

Credentials must live in Vault under a database-lifecycle path rather than an
application-deployment path, for example:

```text
kv/platform/mysql/accounts/<cluster>/<account>
```

An ExternalSecret in the `mysql` namespace should materialize one distinct
Kubernetes Secret per account. The PXC user declaration then references only
that Secret. A separate, platform-generated ExternalSecret may deliver the
necessary fields to the authorized application namespace.

Git must contain only:

- cluster and account names;
- exact databases and privileges;
- the Vault path;
- Secret object names and keys; and
- account lifecycle state.

Git must not contain a password, a complete connection URL containing a
password, a client private key, or a decoded Kubernetes Secret.

## Source-network restriction

Both `scg_prod` and `scg_dev` must be reachable only from:

```text
115.145.0.0/16
```

MySQL 8 supports account host values such as
`'scg_prod'@'115.145.0.0/16'`. That is not reliable through the current
operator-managed HAProxy path. On normal port 3306 connections, PXC generally
sees the HAProxy Pod address rather than the original client address, so MySQL
cannot match the campus client CIDR directly.

The source restriction should therefore be enforced before HAProxy, using the
external Service, load balancer or firewall, and Cilium where appropriate. A
future externally exposed Service should include the equivalent of:

```yaml
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  loadBalancerSourceRanges:
    - 115.145.0.0/16
```

The exact source-IP preservation behavior must be verified with the selected
load-balancer implementation before relying on this configuration. A Cilium
policy or upstream firewall should provide a second layer. The MySQL account may
still need `hosts: ["%"]` because PXC sees HAProxy as the immediate client;
`%` does not imply public reachability when the endpoint itself is restricted.

Proxy Protocol could preserve an original address, but it requires an upstream
proxy that sends Proxy Protocol to HAProxy's dedicated listener and matching
PXC `proxy_protocol_networks` configuration. A normal MySQL client must not
connect directly to that listener. This complexity is not justified unless
MySQL-level source attribution becomes a firm requirement.

The repository currently defines no external MySQL LoadBalancer. External
access must not be enabled without the source-range and TLS controls in the
same reviewed change.

## Privileged administration

### Routine administration

Routine administration should not use `root`. The preferred long-term model is
Vault Database Secrets Engine issuing short-lived DBA accounts after GitHub OIDC
authentication:

```text
GitHub platform group
        -> Vault OIDC
        -> short-lived MySQL DBA credential
        -> audited administrative session
```

Recommended properties are:

- only the GitHub `platform` group can request the role;
- each credential has a short TTL, such as 30 minutes;
- Vault creates a unique MySQL username for each lease;
- expiration revokes or drops the temporary account;
- issuance and revocation appear in Vault audit logs; and
- the granted role is narrower than `root` whenever possible.

This converts platform group membership into the authorization boundary and
avoids a permanent shared administrator password.

### Root break-glass access

Percona Operator must continue to own the PXC system-user Secret. The `root`
credential must not be copied into application secrets or routinely distributed
to people. Root access should require a platform-controlled path such as:

1. valid Kubernetes cluster credentials;
2. platform RBAC permitting the approved MySQL administrative command;
3. an ephemeral in-cluster MySQL client; and
4. direct Secret injection without printing the root password.

A future `k mysql shell <cluster> --admin` command could implement this flow for
platform engineers. The command must be auditable and must delete the ephemeral
client after use.

Encrypting a reusable root password with SOPS is better than committing
plaintext but is not the preferred authentication boundary. Anyone able to
decrypt it obtains the same long-lived identity, individual activity is hard to
attribute, and removal from the recipient list does not revoke a previously
copied password. SOPS may be part of an approved recovery backup but should not
be the normal root-access mechanism.

## Shared-account risk

`scg_prod` and `scg_dev` are shared identities. MySQL audit data cannot reliably
attribute statements to an individual holder. Their compromise also affects
every database in the corresponding environment.

They can be an initial compatibility mechanism, but the preferred future model
is:

```text
individual or workload identity -> environment/database role -> exact grants
```

Examples include one account per application workload and short-lived human
accounts receiving a production or development role. This permits independent
rotation, revocation, and attribution without changing the database catalog.

## Proposed implementation order

1. Add a reviewed database catalog with exact cluster and environment fields.
2. Add repository checks for suffix consistency, cluster retention protections,
   prohibited PVC finalizers, and forbidden account privileges.
3. Create Vault paths and dedicated ExternalSecrets for `scg_prod` and
   `scg_dev` without exposing credential values.
4. Generate exact `spec.users[].dbs` lists from the catalog.
5. Validate user creation, effective grants, TLS, and password rotation on a
   disposable database before production use.
6. Design and locally validate an external MySQL Service restricted to
   `115.145.0.0/16`; do not expose it as part of ordinary validation.
7. Add explicit account `present`, `locked`, and `absent` procedures.
8. Add a platform-only, audited administrative workflow.
9. Introduce Vault dynamic DBA credentials before treating the design as the
   final routine-administration model.
10. Test restoration of retained PVC data and independently stored backups.

## References

- [Percona Operator 1.20: users](https://docs.percona.com/percona-operator-for-xtradb-cluster/1.20.0/users.html)
- [Percona Operator 1.20: deleting the cluster](https://docs.percona.com/percona-operator-for-xtradb-cluster/1.20.0/delete.html)
- [Percona Operator 1.20: exposing the cluster](https://docs.percona.com/percona-operator-for-xtradb-cluster/1.20.0/expose.html)
- [Percona Operator 1.20: HAProxy configuration](https://docs.percona.com/percona-operator-for-xtradb-cluster/1.20.0/haproxy-conf.html)
- [MySQL 8.0 account names](https://dev.mysql.com/doc/refman/8.0/en/account-names.html)
- [MySQL 8.0 `GRANT`](https://dev.mysql.com/doc/refman/8.0/en/grant.html)
- [Argo CD resource deletion controls](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/#no-resource-deletion)
