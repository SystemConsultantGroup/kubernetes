[한국어](vault.md) | English

# vault

Initializes and configures the Vault deployment reconciled by Argo CD.

## Behavior

The command:

1. verifies that the external KMS Worker is healthy;
1. decrypts the Transit token from `secrets/vault.yaml` and materializes the
   `vault/vault-transit-seal` Kubernetes Secret;
1. waits for the Argo CD-managed Vault pod and API;
1. if Vault is uninitialized, initializes it with five recovery shares and a
   threshold of three;
1. immediately encrypts the one-time initialization response into
   `secrets/vault-recovery.yaml`;
1. enables the file audit device, KV v2 at `kv`, and Kubernetes authentication;
1. creates the shared managed-application policy and Kubernetes-auth role;
1. creates the namespace-scoped MySQL backup policy and Kubernetes-auth role;
1. configures GitHub authentication through Argo CD Dex, makes it the default
   web UI method, and maps the `active` and `platform` teams to Vault policies;
   and
1. waits for `https://vault.platform.scg.sh/v1/sys/health`.

If Vault is already initialized and its recovery file still contains a valid
initial root token, the command reconciles the privileged configuration.
After that token is revoked and removed, it validates and retains the recovery
file without attempting privileged reconciliation. Vault cannot return recovery
shares or the initial root token a second time.

If initialization succeeds but SOPS encryption fails, the command preserves the
plaintext response in a mode-`0600` temporary file and prints only its path.
Secure that file immediately. On success, temporary plaintext is removed.

`secrets/vault-recovery.yaml` is generated output tied to the current Vault
storage. Commit its encrypted replacement after every destructive reset. It
cannot initialize a new Vault and becomes obsolete when the Raft data is lost.

## Usage

```bash
k initialize vault
```

## Prerequisites

- The KMS Worker is deployed and healthy at
  `https://kms.vault.platform.scg.sh`.
- `secrets/vault.yaml` is decryptable and contains the Worker key backup and
  Transit token.
- `secrets/bootstrap.yaml` contains the Dex client secret shared with Vault.
- The local age key can decrypt the existing recovery file and SOPS has at
  least one configured recipient for encrypting its replacement.
- Argo CD has reconciled Vault, cert-manager, the Gateway, and `local-data`.
- The committed Vault Application and values are present on the repository's
  `main` branch because the Argo CD Application reads from `main`.

This is a live operation. It creates cluster resources and may initialize a new
Vault. It never reinitializes an existing Vault.
