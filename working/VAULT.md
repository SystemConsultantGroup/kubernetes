# Vault application secrets

## Status

The design is approved and Vault is active, initialized, and auto-unsealed.
KV v2 is mounted at `kv`, Kubernetes authentication is configured, and file
auditing writes to the audit PVC. Managed application secret generation remains
disabled centrally until scoped policies and roles exist. Application metadata
does not contain secret configuration.

The single `scc` node provides the non-default `local-data` StorageClass at
`/var/lib/local-data` on Talos `EPHEMERAL` storage. Vault requests retained Raft
and audit PVCs from this class. The storage is node-local and is lost on a Talos
EPHEMERAL reset. This is intentional: repository-driven resets rebuild Vault
with empty data and replace the generated recovery material.

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
deletionPolicy: Delete
target:
  creationPolicy: Owner
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

The deployment uses the official Vault chart and integrated Raft storage. The
current configuration requests `local-data` and runs one Raft member. Continued
production use requires all of the following:

1. the `local-data` StorageClass is reconciled and locally verified;
1. enough independent nodes exist before increasing the Raft replica count;
1. end-to-end TLS and CA distribution to application namespaces;
1. an initialization and unseal procedure that SOPS-encrypts recovery material
   outside the cluster;
1. Vault audit devices with durable output; and
1. an operator workflow for KV, auth mount, policy, and role provisioning.

Three Vault pods on one physical node are not highly available. The current
single-node cluster must not represent such a deployment as HA.

## Activation sequence

Activate the system in this order:

1. provide durable storage and the Vault TLS trust chain;
1. include the staged Vault Application in `argocd/kustomization.yaml`;
1. run `k install vault` to initialize, auto-unseal, and replace encrypted
   recovery output;
1. enable KV v2 at `kv` and Kubernetes auth at `kubernetes`;
1. configure scoped policies and roles for each application;
1. migrate and rename existing secrets into generated paths;
1. verify ESO synchronization and Reloader rollouts in testing;
1. set `_context.secrets.enabled: true` and the trusted HTTPS Vault server URL
   in both managed ApplicationSets; and
1. verify production paths before promotion.

The central gate allows activation without changing any application
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
