# list

Lists configured age recipients and marks the local recipient when available.

## Description

Reads recipients from `secrets/state.yaml`, sorts them by alias, and
prints each alias with its age recipient. When the local key derives a matching
recipient, the line ends with `(me)`.

## Usage

```
k secrets recipients list
```

## Prerequisites

- `state.yaml` must contain the values required by the `k` dispatcher.
- `secrets/state.yaml` and `yq` must be available.
- If the local key file exists, `age-keygen` must be available to derive its recipient.

## Notes

- The key path is `SOPS_AGE_KEY_FILE` when set; otherwise it is
  `${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`.
- A missing key is not created, and no `(me)` marker is printed without it.
- The command accepts no arguments.
