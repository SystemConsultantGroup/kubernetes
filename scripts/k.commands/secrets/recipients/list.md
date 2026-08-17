# list

Lists configured age recipients and marks the local recipient when available.

## Behavior

Reads aliases from `secrets/state.yaml`, sorts them by alias, and prints each
alias with its recipient. A matching local recipient is marked `(me)`.

The command does not create a missing local key and does not change repository
files. If the key exists, `age-keygen` derives the local recipient for the
comparison.

## Usage

```bash
k secrets recipients list
```

## Prerequisites

- Run inside `nix develop`.
- `secrets/state.yaml` and `yq` exist.
- If the local key exists, `age-keygen` can read it.

The key path is `SOPS_AGE_KEY_FILE` when set; otherwise it is
`${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`. The command accepts no
arguments.
