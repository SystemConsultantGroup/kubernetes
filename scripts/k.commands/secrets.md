# secrets

Manages SOPS-encrypted repository secrets and their age recipients.

## Description

Dispatches commands for encrypted YAML files under `secrets/` and the recipient
map in `secrets/state.yaml`. Secret editing and recipient changes
synchronize the generated root `.sops.yaml` with that map; `check` verifies the
same relationship.

## Usage

```
k secrets <command> [args...]
```

## Prerequisites

- `state.yaml` must contain the values required by the `k` dispatcher.
- The repository's `yq`, `sops`, `age`, and `age-keygen` commands must be available.

## Subcommands

- `check` — Verifies the local age recipient, SOPS configuration, and encrypted secret files.
- `edit <secret>` — Opens one encrypted secret with `sops`.
- `recipients` — Manages configured age recipients.

## Notes

- Run `k secrets` without a command to print the subcommand list.
- The legacy `k secrets recipient` spelling is accepted as an alias for `recipients`.
