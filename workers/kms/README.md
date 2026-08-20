# Vault KMS Worker

This Cloudflare Worker implements the minimal Vault Transit HTTP API needed by
HashiCorp Vault's `seal "transit"` auto-unseal backend. It is intended to run at
`kms.vault.platform.scg.sh`.

It is deliberately not a general Transit server. Only these operations exist:

```text
PUT|POST /v1/transit/encrypt/vault-root
PUT|POST /v1/transit/decrypt/vault-root
GET      /healthz
```

Encryption uses AES-256-GCM with a fresh 96-bit nonce. Ciphertexts have the
Transit-compatible shape `vault:vN:<base64url>` and authenticate their key
version as additional data. The Worker retains no request state.

## Security model

The encryption keys and API token are Cloudflare secret bindings. Their values
are hidden by Wrangler and the dashboard, but Worker code can access them.
Anyone who can deploy modified code to this Worker can therefore exfiltrate the
keys. This is useful as an independently hosted auto-unseal service, but it is
not equivalent to an HSM or a KMS with non-exportable keys.

Protect Cloudflare deployment credentials separately from Kubernetes and Vault
credentials. Do not enable request-body logging. Keep an offline, access-
controlled backup of every key version: losing a key that protects Vault data
can make Vault unrecoverable.

Every request to a Transit endpoint must have the configured shared secret in
`X-Vault-Token`. Optional mTLS enforcement is also available, but it requires
Cloudflare client-certificate validation to be configured for the hostname.

## Local development

Enter the repository development shell, install the locked dependencies, and
run the checks:

```bash
nix develop
cd workers/kms
bun install --frozen-lockfile
bun run check
```

Copy `.dev.vars.example` to `.dev.vars` and replace both values before running
`bun run dev`. `.dev.vars` is ignored by Git.

`KMS_KEY_V1` must be exactly 32 cryptographically random bytes encoded with
standard base64. Generate it using a trusted CSPRNG and preserve the original
value in the platform password manager or another approved offline recovery
location.

## Cloudflare configuration

Authenticate Wrangler to the Cloudflare account that owns `platform.scg.sh`,
then create the secret bindings without placing their values on a command line:

```bash
bun run wrangler secret put KMS_AUTH_TOKEN
bun run wrangler secret put KMS_KEY_V1
```

The token should be a long, random value. The key must be the base64 encoding
described above. Deploy only after both secrets exist:

```bash
bun run deploy
```

`wrangler.jsonc` creates `kms.vault.platform.scg.sh` as a Custom Domain and
disables the public `workers.dev` and preview URLs. If the service is moved to
`kms.platform.scg.sh`, change the Custom Domain and Vault `address` together;
do not change the Transit mount or key name on an initialized Vault without a
planned seal migration.

### Optional mTLS

Configure Cloudflare API Shield client-certificate validation for the custom
domain and configure Vault to present that certificate. Then set
`REQUIRE_MTLS` to exactly `true` in `wrangler.jsonc` and redeploy. Only `true`
and `false` are accepted, so a typo makes requests fail closed. The Worker
requires Cloudflare's `certVerified` value to be `SUCCESS` and rejects revoked
certificates. Keep token authentication enabled as a second factor.

## Vault configuration

Supply the same token stored in `KMS_AUTH_TOKEN` to Vault through a Kubernetes
Secret exposed as `VAULT_TRANSIT_SEAL_TOKEN`:

```hcl
seal "transit" {
  address         = "https://kms.vault.platform.scg.sh"
  token           = "env://VAULT_TRANSIT_SEAL_TOKEN"
  disable_renewal = "true"

  mount_path = "transit"
  key_name   = "vault-root"
}
```

`disable_renewal` must remain true because this Worker intentionally does not
implement Vault token renewal. Use Vault's documented seal-migration procedure
when adding this seal to an initialized Vault. Recovery keys cannot unseal Vault
while the Worker or its key is unavailable.

## Key rotation

Rotation is deployment-driven and has no HTTP administration API:

1. Generate and back up a new 32-byte key.
1. Add it as `KMS_KEY_V2` with `wrangler secret put`. Keep `KMS_KEY_V1`.
1. Change `CURRENT_KEY_VERSION` in `wrangler.jsonc` to `v2` and deploy.
1. Restart a non-critical Vault node and verify auto-unseal before rolling the
   remaining nodes.
1. Retain every old key binding that may protect stored Vault ciphertext.

Repeat with monotonically increasing names (`KMS_KEY_V3`, and so on). Never
replace an existing version's value.

## Validation

```bash
bun run typecheck
bun test
bun run wrangler deploy --dry-run
```

The tests cover authentication, Transit response compatibility, randomized
ciphertexts, tamper rejection, mTLS enforcement, and decryption across key
rotation.
