[한국어](edit.md) | English

# edit

Opens a named encrypted secret with SOPS.

## Behavior

The argument selects `secrets/<secret>.yaml`.
Names may contain lowercase letters, digits, `.`, `_`, and `-`; they cannot
start with `.` or be `state`.
Before SOPS opens the file, the command regenerates `.sops.yaml` from
`secrets/state.yaml`.

With no argument or the wrong number of arguments, it lists available secret
names and exits with a usage error.
It does not accept flags or extra arguments.

## Usage

```bash
k secrets edit <secret>
```

## Prerequisites

- Run inside `nix develop`.
- The selected secret and `secrets/state.yaml` exist.
- The local age key can decrypt the selected file.

SOPS controls the editor and writes the file back encrypted.
Never copy plaintext out of the editor or commit a decrypted file.
