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

Both volumes are node-local and require off-cluster snapshots for disaster
recovery.

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

The Kubernetes token is materialized as `vault/vault-transit-seal` during Argo
CD bootstrap. Secret values must only move through standard input:

```bash
sops decrypt --extract '["VAULT_TRANSIT_SEAL_KEY_V1"]' secrets/vault.yaml |
  (cd workers/kms && bun run wrangler secret put KMS_KEY_V1)
sops decrypt --extract '["VAULT_TRANSIT_SEAL_TOKEN"]' secrets/vault.yaml |
  (cd workers/kms && bun run wrangler secret put KMS_AUTH_TOKEN)
sops decrypt --extract '["VAULT_TRANSIT_SEAL_TOKEN"]' secrets/vault.yaml |
  kubectl -n vault create secret generic vault-transit-seal \
    --from-file=token=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
```

Never replace `KMS_KEY_V1` after Vault initialization. Follow the Worker rotation
procedure and retain old versions.

## Initialization

Initialize exactly once after the StatefulSet, certificate, and Worker are
healthy. Capture the JSON response directly into a SOPS-encrypted file; never
print recovery keys or the initial root token:

```bash
umask 077
kubectl -n vault exec vault-0 -- \
  vault operator init -format=json -recovery-shares=5 -recovery-threshold=3 |
  sops encrypt --filename-override secrets/vault-init.yaml \
    --input-type json --output-type yaml /dev/stdin >secrets/vault-init.yaml
```

Verify the encrypted file is decryptable before continuing. Auto-unseal recovery
keys do not substitute for the Worker encryption key and cannot unseal Vault if
the Worker key is lost.

After initialization, authenticate without exposing the root token in process
arguments and enable the audit device, KV v2, and Kubernetes authentication.
Record any long-lived operator authentication design before revoking the initial
root token.

## Operations

Use the public address for operator commands:

```bash
export VAULT_ADDR=https://vault.platform.scg.sh
vault status
```

Take regular Raft snapshots and encrypt them before moving them off the node:

```bash
vault operator raft snapshot save /secure/path/vault.snap
```

The initial post-bootstrap snapshot is stored as SOPS-encrypted base64 in
`secrets/vault-snapshot.yaml`. Future snapshots should go to a dedicated,
versioned off-cluster backup target rather than accumulating in Git.

A snapshot is useful only together with the Worker key version that protected
Vault at the time. Test restoration outside the live cluster before relying on
the backup procedure.
