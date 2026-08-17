# remove

Removes a named age recipient and rekeys all encrypted repository secrets.

## Description

Looks up `<name>` in `secrets/state.yaml` and refuses unknown names or
removal of the last configured recipient. For a valid removal, it deletes the
mapping, regenerates `.sops.yaml`, and runs `sops updatekeys --yes` for every
encrypted secret file.

## Usage

```
k secrets recipients remove <name>
```

## Prerequisites

- `state.yaml` must contain the values required by the `k` dispatcher.
- `secrets/state.yaml` and `.sops.yaml` must exist.
- Encrypted secret YAML files, `yq`, and `sops` must be available.
- SOPS must be able to decrypt and rekey the existing secrets with your age key.

## Notes

- The command accepts exactly one name and no flags or confirmation option.
- Removing a recipient removes its access when the encrypted files are rekeyed.
- If rekeying fails, the recipient map, `.sops.yaml`, and secret files are restored.
