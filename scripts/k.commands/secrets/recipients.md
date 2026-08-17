# recipients

Manages the age recipients used to encrypt repository secrets.

## Description

Reads and updates the recipient map in `secrets/state.yaml`. Recipient
changes regenerate the root `.sops.yaml` and rekey every encrypted secret file
under `secrets/`.

## Usage

```
k secrets recipients <command> [args...]
```

## Prerequisites

- `state.yaml` must contain the values required by the `k` dispatcher.
- `yq` and the required `age`/`sops` commands must be available.
- `add`, `list`, and `remove` require `secrets/state.yaml`; `add` and
  `remove` also require `.sops.yaml`.

## Subcommands

- `add <name> <age1...>` — Adds a recipient and rekeys all encrypted secrets.
- `list` — Lists recipients and marks the local one with `(me)` when available.
- `me` — Ensures a local age key exists and prints its recipient and aliases.
- `remove <name>` — Removes a recipient and rekeys all encrypted secrets.

## Notes

- Run `k secrets recipients` without a command to print the subcommand list.
- Recipient changes use `sops updatekeys --yes`; they are not interactive.
