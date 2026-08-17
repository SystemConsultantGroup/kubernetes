# secrets

Manages SOPS-encrypted YAML files and their age recipients.

## Subcommands

- `check` verifies the local recipient, `.sops.yaml`, and every encrypted secret.
- `edit <secret>` opens `secrets/<secret>.yaml` with SOPS.
- `recipients` manages the configured age recipients.

## Usage

```bash
k secrets <command> [args...]
```

Running `k secrets` lists subcommands. The legacy singular spelling
`k secrets recipient` remains an alias for `recipients`.

## Prerequisites

Run inside `nix develop`, which supplies `yq`, `sops`, `age`, and `age-keygen`.
The dispatcher also requires the cluster values in `state.yaml`.

## Behavior

`secrets/state.yaml` is the public recipient map. The command derives the root
[`.sops.yaml`](../../.sops.yaml) from that map and the encrypted files. Editing a
secret synchronizes the generated configuration; adding or removing a recipient
also rekeys every encrypted top-level YAML file under `secrets/`.

Do not print decrypted values or run recipient changes without an explicit
access change being approved.
