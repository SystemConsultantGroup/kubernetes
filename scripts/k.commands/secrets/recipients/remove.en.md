[한국어](remove.md) | English

# remove

Removes a named age recipient and rekeys every encrypted repository secret.

> [!CAUTION]
> This revokes the recipient's access only after all encrypted files are
> successfully rekeyed.
> The command is non-interactive and does not ask for confirmation.

## Behavior

The command rejects unknown aliases and removal of the last configured
recipient.
For a valid alias, it updates `secrets/state.yaml`, regenerates `.sops.yaml`,
and runs `sops updatekeys --yes` for every encrypted top-level YAML file.

If rekeying fails, the recipient map, `.sops.yaml`, and secret files are
restored from backups.

## Usage

```bash
k secrets recipients remove <name>
```

The command accepts exactly one alias and no flags.

## Prerequisites

- Run inside `nix develop`.
- `secrets/state.yaml` and `.sops.yaml` exist.
- SOPS can decrypt and rekey the existing encrypted secrets with the local age
  key.
