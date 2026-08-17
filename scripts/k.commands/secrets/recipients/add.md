# add

Adds a named age recipient and rekeys all encrypted repository secrets.

## Description

Validates the name and the supplied age recipient, then adds the mapping to
`secrets/state.yaml`. It regenerates `.sops.yaml` and runs
`sops updatekeys --yes` for every encrypted secret file. Duplicate names or
recipients are rejected, except an existing name with the same recipient,
which is reported as already configured.

## Usage

```
k secrets recipients add <name> <age1...>
```

## Prerequisites

- `state.yaml` must contain the values required by the `k` dispatcher.
- `secrets/state.yaml` and `.sops.yaml` must exist.
- Encrypted secret YAML files, `yq`, `age`, and `sops` must be available.
- SOPS must be able to decrypt and rekey the existing secrets with your age key.

## Notes

- `<name>` starts with a lowercase letter or digit and may contain lowercase
  letters, digits, `.`, `_`, or `-`.
- The command accepts exactly one recipient argument and no flags.
- If rekeying fails, the recipient map, `.sops.yaml`, and secret files are restored.
