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

Both volumes are node-local and are intentionally outside this repository's
reset contract. A destructive cluster reset starts Vault with empty storage.

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

`k install vault` materializes the Kubernetes token as
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

Run the idempotent installer after Argo CD and the Worker are ready:

```bash
k install vault
```

For a fresh data volume, it initializes Vault, immediately SOPS-encrypts the
one-time response into `secrets/vault-recovery.yaml`, and configures auditing,
KV v2, and Kubernetes authentication. Commit the changed encrypted recovery
file after each destructive reset. On an initialized Vault it validates and
retains the existing file.

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

After configuration, select **OIDC** in the Vault UI or use:

```bash
export VAULT_ADDR=https://vault.platform.scg.sh
vault login -method=oidc role=github
```

Test a platform login before revoking the initial root token and removing it
from `vault-recovery.yaml`. Recovery shares remain the break-glass mechanism if
Dex or GitHub is unavailable. The current deployment's initial root token has
been revoked and removed.

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
