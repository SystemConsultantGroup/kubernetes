# recipients

Manages the age recipients that can decrypt repository secrets.

## Subcommands

- `add <name> <recipient>` adds a recipient and rekeys every encrypted secret.
- `list` lists aliases and marks the local recipient with `(me)`.
- `me` creates or inspects the local age key and prints its recipient.
- `remove <name>` removes a recipient and rekeys every encrypted secret.

## Usage

```bash
k secrets recipients <command> [args...]
```

Running `k secrets recipients` lists subcommands. The `add` and `remove`
commands update `secrets/state.yaml`, regenerate `.sops.yaml`, and run
non-interactive SOPS rekeying for every top-level encrypted YAML file.

> [!CAUTION]
> Adding grants access to all encrypted secrets. Removing revokes access only
> after rekeying succeeds. Review the recipient and alias before either change.

## Prerequisites

- Run inside `nix develop`.
- `secrets/state.yaml` exists for `add`, `list`, and `remove`.
- `.sops.yaml` exists for `add` and `remove`.
- The local age key can decrypt and rekey the existing secrets for `add` and
  `remove`.
