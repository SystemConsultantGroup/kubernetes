# edit

Opens a named encrypted secret for editing with `sops`.

## Description

The secret name maps to `secrets/<secret>.yaml` after validation. Names must
use lowercase letters, digits, `.`, `_`, or `-`, must not start with `.`, and
cannot be `state`. Before opening the file, the command synchronizes the
root `.sops.yaml` from `secrets/state.yaml`.

## Usage

```
k secrets edit <secret>
```

## Prerequisites

- `state.yaml` must contain the values required by the `k` dispatcher.
- The selected `secrets/<secret>.yaml` and `secrets/state.yaml` must exist.
- At least one encrypted secret YAML file and the `sops` and `yq` commands are required.

## Notes

- With no argument, or with an argument count other than one, the command
  prints the available secret names and exits with a usage error.
- Synchronizing `.sops.yaml` happens before `sops` opens the selected file.
- The command does not accept flags or extra arguments.
