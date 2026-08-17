# Encrypted secrets

This directory contains the encrypted values needed to bootstrap and operate
the cluster. SOPS uses age recipients from [`state.yaml`](state.yaml) and the
generated root [`.sops.yaml`](../.sops.yaml).

## Files

| File | Contents |
| --- | --- |
| `state.yaml` | Public aliases and age recipients; it contains no secret values |
| `bootstrap.yaml` | Encrypted Argo CD OAuth, Cloudflare, and ZeroSSL bootstrap values |
| `talos.yaml` | Encrypted Talos cluster secrets |

Secret YAML files must remain encrypted in Git. Recipient aliases and recipient
identifiers are public configuration; the encrypted data keys are not.

## Getting access

Create or inspect the local age key and print its recipient:

```bash
k secrets recipients me
```

Send the printed recipient to an existing operator. They can add a named
recipient and rekey all encrypted files:

```bash
k secrets recipients add <name> <age1...>
```

After access is granted, validate the local key, recipient map, SOPS
configuration, and every encrypted file:

```bash
k secrets check
```

The default age key path is `${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`.
Set `SOPS_AGE_KEY_FILE` to use another path.

## Editing values

Use the command wrapper instead of opening encrypted files manually:

```bash
k secrets edit bootstrap
k secrets edit talos
```

The bootstrap file must contain real values for
`ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`, `CLOUDFLARE_API_TOKEN`, and
`ZEROSSL_EAB_HMAC_KEY` before `k install` can complete. The Cloudflare token
must be permitted to read the relevant zone and edit its DNS records.

Do not print decrypted content, commit plaintext, or add credentials to
application metadata, platform values, patches, or documentation. Do not hand
edit `.sops.yaml`; the recipient workflow derives it from this directory's
public recipient map.
