# me

Ensures a local age key exists and prints its recipient and configured aliases.

## Description

Uses `SOPS_AGE_KEY_FILE` when set, or
`${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt` by default. If the key is
missing, creates its parent directory and generates the key with `age-keygen`.
It then prints the derived recipient and any matching aliases from
`secrets/recipients.yaml`.

## Usage

```
k secrets recipients me
```

## Prerequisites

- `state.yaml` must contain the values required by the `k` dispatcher.
- The key directory must be writable and `age-keygen` must be available.

## Notes

- The generated key directory is set to mode `700` and the key file to `600`.
- An existing key path that is not a regular file is rejected.
- If no configured alias matches, the command reports that the recipient is not configured.
- The command accepts no arguments.
