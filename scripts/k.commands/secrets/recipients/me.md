# me

Creates or inspects the local age key and prints its recipient and aliases.

## Behavior

Uses `SOPS_AGE_KEY_FILE` when set, or
`${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt` by default.
If the file is missing, it creates the parent directory and generates a key.
It then prints the derived recipient and any matching aliases in
`secrets/state.yaml`.

The key directory is set to mode `700` and the key file to `600`.
This command creates only the local key; it does not add the recipient to the
repository or grant access to encrypted files.

## Usage

```bash
k secrets recipients me
```

## Prerequisites

- Run inside `nix develop`.
- The key directory is writable and `age-keygen` is available.

An existing key path that is not a regular file is rejected.
The command accepts no arguments.
