[한국어](add.md) | English

# add

Adds a named age recipient and rekeys every encrypted repository secret.

> [!CAUTION]
> This command changes who can decrypt all repository secrets.
> It is non-interactive and does not ask for confirmation.

## Behavior

The command validates the alias and `age1...` recipient, rejects duplicate
aliases or recipients, updates `secrets/state.yaml`, regenerates `.sops.yaml`,
and runs `sops updatekeys --yes` for every encrypted top-level YAML file.
An existing alias with the same recipient is reported as already configured.

If any rekey step fails, the recipient map, `.sops.yaml`, and secret files are
restored from backups.

## Usage

```bash
k secrets recipients add <name> <age1...>
```

`<name>` starts with a lowercase letter or digit and may contain lowercase
letters, digits, `.`, `_`, and `-`.
The command accepts exactly two arguments.

## Prerequisites

- Run inside `nix develop`.
- `secrets/state.yaml` and `.sops.yaml` exist.
- At least one encrypted secret exists, and SOPS can decrypt and rekey it with
  the local age key.
