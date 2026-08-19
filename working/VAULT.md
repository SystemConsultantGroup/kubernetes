# Vault application secrets

## Status

The base platform is deployed and healthy. Vault 2.0.4 is active at
`vault.platform.scg.sh`, initialized, and auto-unsealed through the
Transit-compatible Worker at `kms.vault.platform.scg.sh`. Argo CD reports both
Vault and its own application as synced and healthy.

KV v2 is mounted at `kv`, Kubernetes authentication is configured, and file
auditing writes to the audit PVC. GitHub operator authentication uses Argo CD
Dex. `SystemConsultantGroup:active` receives `github-active` and can manage
values under `kv`; `SystemConsultantGroup:platform` additionally receives
`github-platform` with administrative access. OIDC is the default web UI login
method. The initial root token has been revoked and removed from the encrypted
recovery file.

Managed application secret generation is enabled centrally. Scoped policies and
Kubernetes roles exist for the `example` application, whose testing path has a
non-sensitive verification value. Application metadata does not contain secret
configuration.

The single `scc` node provides the non-default `local-data` StorageClass at
`/var/lib/local-data` on Talos `EPHEMERAL` storage. Vault requests retained Raft
and audit PVCs from this class. The storage is node-local and is lost on a Talos
EPHEMERAL reset. This is intentional: repository-driven resets rebuild Vault
with empty data and replace `secrets/vault-recovery.yaml`. The repository does
not retain Raft snapshots or restore Vault data.

## Decisions

Runtime application secrets use:

- HashiCorp Vault as the authority;
- the Vault KV v2 secrets engine mounted at `kv`;
- External Secrets Operator to synchronize values into Kubernetes Secrets;
- generated namespaced SecretStores using Kubernetes authentication;
- automatic environment injection for every managed workload;
- Reloader to roll workloads after Secret creation, changes, or deletion; and
- scoped Vault roles instead of one cluster-wide Vault identity.

Custom Kustomize applications do not receive generated secret resources.

## Operator access and recovery

Enter the development shell and authenticate through GitHub:

```bash
nix develop
export VAULT_ADDR=https://vault.platform.scg.sh
vault login -method=oidc role=github
```

The `platform` team is nested under `active`, so platform members receive both
identity policies. Operator tokens have a one-hour TTL, are renewable, and have
an eight-hour maximum TTL. Use `vault token renew` instead of repeating the
browser login during an active session.

`secrets/vault-recovery.yaml` contains five SOPS-encrypted recovery shares with
a threshold of three for the current Raft data. It no longer contains an initial
root token. Recovery shares can authorize root-token generation and rekeying,
but cannot unseal Vault if the Worker or its encryption key is unavailable.
`secrets/vault.yaml` separately retains the Worker's seal key and Transit token.

`k install vault` restores the Kubernetes seal Secret, applies Vault, initializes
fresh storage, captures and encrypts new recovery material, and configures the
base auth methods and operator policies. On an already initialized deployment
without a bootstrap root token, it validates the recovery file without trying
to reconcile privileged Vault configuration.

## Terminology

A Vault KV secret is a map stored at one logical path. Each entry is a key-value
pair. A Kubernetes Secret is a namespaced resource whose data is also a map of
keys to values.

For example:

```text
Mount:  kv
Path:   applications/alumni/production/be
Key:    MINIO_ENDPOINT
Value:  https://minio.example.org
```

The logical path shown by the Vault CLI and used by External Secrets Operator
omits the KV v2 API segment. Vault policies and direct API requests include it:

```text
Logical path:  applications/alumni/production/be
CLI path:      kv/applications/alumni/production/be
Policy path:   kv/data/applications/alumni/production/be
```

Vault path components are a naming convention, not Vault projects or physical
folders.

## Paths

Every managed workload derives its paths without application metadata:

```text
applications/<application>/<instance-type>/<workload>
```

Examples:

```text
applications/alumni/production/be
applications/alumni/testing/be
applications/alumni/preview/be
```

Production and testing use one source. Preview uses testing as its base and
preview as an ordered override:

```yaml
dataFrom:
  - extract:
      key: applications/alumni/testing/be
  - extract:
      key: applications/alumni/preview/be
```

Later sources override keys from earlier sources. A partial preview secret
therefore inherits unspecified testing keys. If neither path exists, no
Kubernetes Secret exists.

Preview code can read testing values under this policy. Testing credentials must
therefore be sandboxed and safe to expose to unreviewed preview workloads.

## Environment injection

Vault keys use portable environment variable names:

```text
DATABASE_URL
MINIO_ACCESS_KEY
MINIO_ENDPOINT
MINIO_SECRET_KEY
```

External Secrets Operator extracts the complete Vault map into a generated
Kubernetes Secret. The application chart references that Secret with optional
`envFrom`, so a workload starts without injected values when Vault has no data
for it.

Explicit `env` entries remain authoritative over `envFrom`. User-supplied
`envFrom` entries are rendered after the generated source and can override a
generated key.

Applications that require a value must validate it at startup. Missing Vault
secrets intentionally fail open at the Kubernetes integration boundary.

## ExternalSecret lifecycle

Generated ExternalSecrets use:

```yaml
refreshPolicy: Periodic
refreshInterval: 15s
target:
  creationPolicy: Owner
  deletionPolicy: Delete
```

This gives the following behavior:

| Vault state | Kubernetes state |
| --- | --- |
| Path absent | Secret absent without `SecretSyncedError` |
| Path created | Secret created within the refresh interval |
| Values changed | Secret updated within the refresh interval |
| Path deleted | Secret deleted within the refresh interval |

External Secrets Operator is pull-based. With Vault Community Edition, a
15-second interval is the upper synchronization delay rather than a true push
event. Vault Enterprise event subscriptions would require Vault Secrets
Operator and are not part of this design.

## Rollouts

Kubernetes does not update a running process's environment when a Secret
changes. Reloader watches generated Secrets and patches the workload pod
template, causing a Kubernetes rolling deployment.

Reloader must have creation and deletion reloads enabled in addition to its
default update handling. It uses the annotation strategy. Generated Argo CD
Applications ignore Reloader's pod-template annotation so self-healing does not
revert the rollout patch.

The resulting flow is:

```text
Vault write
  → ESO reconciliation within 15 seconds
  → Kubernetes Secret create, update, or delete
  → Reloader watch event
  → Deployment pod-template patch
  → rolling deployment
```

This is operationally equivalent to a repository change triggering a new
rollout, but it does not create a Git commit or a new Argo CD source revision.
Vault audit logs record the source change.

## Scoped authentication

Each generated namespace contains a Vault authentication ServiceAccount and a
namespaced SecretStore. The store authenticates to Vault's Kubernetes auth mount
with audience `vault`.

Expected Vault roles are:

```text
<application>-production
<application>-testing
<application>-preview
```

Expected policy access is:

```text
<application>-production → kv/data/applications/<application>/production/*
<application>-testing    → kv/data/applications/<application>/testing/*
<application>-preview    → kv/data/applications/<application>/testing/*
                           kv/data/applications/<application>/preview/*
```

Production and testing roles bind to their exact namespaces. Preview roles bind
to preview namespaces selected by both existing namespace labels:

```yaml
platform.scg.sh/application: <application>
platform.scg.sh/instance-type: preview
```

The preview role needs permission to read namespace labels during Kubernetes
authentication. A preview role can read testing paths because testing is the
approved fallback.

Scoped stores ensure that changing an ExternalSecret path cannot cross the
Vault policy boundary. The platform still controls generated paths and does not
expose path overrides in application metadata.

## Vault deployment

The deployment uses the official Vault chart and integrated Raft storage. It
runs one Raft member and is intentionally not represented as highly available.
Do not increase the replica count until independent nodes and storage exist.

TLS is active end to end: the public Gateway terminates client TLS and validates
the TLS connection to Vault with the pinned issuer chain. Auto-unseal has been
restart-tested. File auditing, KV v2, Kubernetes auth, GitHub OIDC, recovery
capture, and operator access are configured and verified.

Current limitations are:

- Raft and audit data are lost with Talos `EPHEMERAL` storage;
- no Vault data backup is retained by design;
- Worker mTLS is optional hardening and is not enabled.

## Remaining activation sequence

The base activation steps and central managed-secret gate are complete. Continue
in this order:

1. test ESO synchronization and Reloader create, update, and deletion behavior
   with the `example` testing workload;
1. run `k configure vault-applications` after adding or removing a managed
   application;
1. seed or migrate application values into the generated `kv/applications/...`
   paths without exposing them in logs or Git;
1. verify production paths before storing production values; and
1. optionally enable Worker mTLS and rehearse recovery-share root generation.

The central gate activates integration without changing any application
`meta.yaml`.

## Migration

Existing secrets such as:

```text
kv/data/alumni-dev-be-secret
kv/data/alumni-prod-be-secret
```

move to:

```text
kv/data/applications/alumni/testing/be
kv/data/applications/alumni/production/be
```

Legacy properties such as `minio-endpoint` should be renamed to environment
variable keys such as `MINIO_ENDPOINT`. Production, testing, and preview maps
should expose the same key names even when values differ.

Migration must copy values without printing them into logs, documentation, or
Git. Source secrets should only be removed after the generated Kubernetes
Secret and rollout behavior have been verified.
