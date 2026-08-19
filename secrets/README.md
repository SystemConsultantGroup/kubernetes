# Encrypted secrets

This directory contains encrypted values required to bootstrap and operate the
cluster.
SOPS uses the public age recipient map in [`state.yaml`](state.yaml) and the
generated root [`.sops.yaml`](../.sops.yaml).

## Files

| File | Contents |
| --- | --- |
| `state.yaml` | Public recipient aliases and age recipients; no secret values |
| `bootstrap.yaml` | Encrypted Argo CD OAuth and webhook, Cloudflare, and ZeroSSL bootstrap values |
| `talos.yaml` | Encrypted Talos cluster secrets |
| `vault.yaml` | Encrypted Vault Transit seal token and recovery copy of the Worker key |
| `vault-recovery.yaml` | Generated, encrypted recovery shares for the current Vault data; the temporary initial root token is removed after operator access is verified |

Keep every file except `state.yaml` encrypted in Git. Do not hand-edit
`.sops.yaml`; the recipient commands regenerate it.

## Grant access

Create or inspect the local age key and print its recipient:

```bash
k secrets recipients me
```

Send the recipient to an existing operator.
After confirming the request, they can add an alias and rekey all encrypted
files:

```bash
k secrets recipients add <name> <age1...>
```

After access is granted, validate the key, recipient map, SOPS configuration,
and encrypted files:

```bash
k secrets check
```

The default key path is `${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`.
Set `SOPS_AGE_KEY_FILE` to use another path.

## Edit values

Use the wrapper so `.sops.yaml` stays synchronized:

```bash
k secrets edit bootstrap
k secrets edit talos
k secrets edit vault
```

Before `k install` can complete, `bootstrap.yaml` must contain real values for
`ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`, `ARGOCD_GITHUB_WEBHOOK_SECRET`,
`CLOUDFLARE_API_TOKEN`, `VAULT_OIDC_CLIENT_SECRET`, and
`ZEROSSL_EAB_HMAC_KEY`. `vault.yaml` must contain
`VAULT_TRANSIT_SEAL_TOKEN` and `VAULT_TRANSIT_SEAL_KEY_V1`.
The Cloudflare token must be allowed to read the relevant zone and edit its DNS
records.

Never print decrypted values, commit plaintext, or put credentials in
application metadata, platform values, patches, or documentation.
Recipient changes grant or revoke access to every encrypted secret and must be
explicitly approved.
