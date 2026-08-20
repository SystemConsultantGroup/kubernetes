# Vault

This component deploys HashiCorp Vault with the official Helm chart, integrated
Raft storage, and automatic unseal through the Transit-compatible Cloudflare
Worker at `kms.vault.platform.scg.sh`.

The current cluster has one physical node, so the single Raft member is durable
but not highly available. Do not increase `server.ha.replicas` until independent
nodes and storage are available.

## Storage and TLS

Vault requests two retained `local-data` volumes:

- 10 GiB at `/vault/data` for integrated Raft storage;
- 10 GiB at `/vault/audit` for file audit logs.

Both volumes are node-local. Their PersistentVolumes use `Retain`, but the
current `/var/lib/local-data` backing path is on Talos `EPHEMERAL` storage and is
therefore inside `k reset`'s wipe boundary. A node reset starts Vault with empty
storage even when the Kubernetes PersistentVolumes were retained.

cert-manager issues `vault-server-tls` for `vault.platform.scg.sh`. The public
Gateway terminates client TLS and uses `BackendTLSPolicy` to establish and
validate a second TLS connection to `vault-active:8200`. The public ZeroSSL
issuer chain is pinned in `vault-backend-ca`; update that bundle if cert-manager
changes issuer chains.

## Transit seal credentials

[`../../../secrets/vault.yaml`](../../../secrets/vault.yaml) stores encrypted
copies of:

- `VAULT_TRANSIT_SEAL_TOKEN`, shared between Vault and the Worker's
  `KMS_AUTH_TOKEN` binding;
- `VAULT_TRANSIT_SEAL_KEY_V1`, the recovery copy of the Worker's `KMS_KEY_V1`
  binding.

`k initialize vault` materializes the Kubernetes token as
`vault/vault-transit-seal`. Worker recovery values must only move through
standard input:

```bash
sops decrypt --extract '["VAULT_TRANSIT_SEAL_KEY_V1"]' secrets/vault.yaml |
  (cd workers/kms && bun run wrangler secret put KMS_KEY_V1)
sops decrypt --extract '["VAULT_TRANSIT_SEAL_TOKEN"]' secrets/vault.yaml |
  (cd workers/kms && bun run wrangler secret put KMS_AUTH_TOKEN)
```

Never replace `KMS_KEY_V1` after Vault initialization. Follow the Worker rotation
procedure and retain old versions.

## Initialization

Run the installer after Argo CD and the Worker are ready:

```bash
k initialize vault
```

For a fresh data volume, it initializes Vault, immediately SOPS-encrypts the
one-time response into `secrets/vault-recovery.yaml`, and configures auditing,
KV v2, Kubernetes authentication, and shared managed-application access. Commit
the changed encrypted recovery file after each destructive reset. On an
initialized Vault it validates and retains the existing file.

The installer reconciles privileged Vault configuration only while the recovery
file contains a valid initial root token. After that token is revoked and
removed, committed policy or authentication changes require a platform operator
to authenticate and apply them as an explicit planned operation; rerunning the
installer does not reconcile those settings.

The recovery file is generated output tied to the current Raft data. Its shares
do not substitute for the Worker key and cannot unseal Vault if that key is
lost.

## Operator authentication

Vault uses Argo CD's bundled Dex as an OIDC provider. Dex delegates to the
existing GitHub OAuth application and emits GitHub team claims. The mappings are:

- `SystemConsultantGroup:active` receives `github-active`, which manages secret
  values and versions under `kv/`;
- `SystemConsultantGroup:platform` receives `github-platform`, which administers
  Vault.

The `platform` team is nested under `active`, so platform operators receive both
policies. Vault has a distinct Dex client secret in `secrets/bootstrap.yaml`;
it does not reuse Argo CD's downstream session or client identity.

The unauthenticated Vault UI presents OIDC as its default method and keeps token
login under **Other** for break-glass access. From the CLI, use:

```bash
export VAULT_ADDR=https://vault.platform.scg.sh
vault login -method=oidc role=github
```

OIDC tokens have a one-hour TTL, are renewable, and have an eight-hour maximum
TTL. Use `vault token renew` during an active operator session rather than
repeating browser login.

Test a platform login before revoking the initial root token and removing it
from `vault-recovery.yaml`. Recovery shares remain the break-glass mechanism if
Dex or GitHub is unavailable. The current deployment's initial root token has
been revoked and removed.

## Application access

Vault bootstrapping creates one `applications` Kubernetes-auth role and policy
for all managed application SecretStores. The role accepts the `vault-auth`
ServiceAccount from any namespace and can read every three-segment path below
`kv/data/applications/`.

Application onboarding does not change Vault configuration. The generated
SecretStores and ExternalSecrets use the shared role and derived paths described
in the [application chart documentation](../../charts/application/README.md).
Application and environment separation is therefore a generated-path convention,
not a Vault authorization boundary; platform review remains required for chart
or authentication changes.

### Managing application values

Members of the GitHub `active` team can manage values through the Vault UI after
OIDC login. Use these KV v2 paths:

| Instance | Path |
| --- | --- |
| Production | `kv/applications/<application>/production/<workload>` |
| Testing | `kv/applications/<application>/testing/<workload>` |
| Preview override | `kv/applications/<application>/preview/<workload>` |

A preview first reads the testing path, then overlays the shared preview path.
The preview path is not pull-request-specific. A missing path is allowed and
leaves the generated environment Secret absent. After a value changes, External
Secrets refreshes the Kubernetes Secret and Reloader rolls the affected managed
Deployment.

Use portable environment-variable keys such as `DATABASE_URL`. Enter values
through an approved secret-handling workflow; do not put plaintext values in Git,
shell history, command output, or documentation.

## Operations

Use the public address for operator commands:

```bash
export VAULT_ADDR=https://vault.platform.scg.sh
vault status
```

This repository restores infrastructure, not Vault data, and does not contain
Raft snapshots. A destructive reset creates new Raft data and replaces
`vault-recovery.yaml`. If data retention becomes a requirement, use a dedicated
encrypted backup system and test restoration separately.
