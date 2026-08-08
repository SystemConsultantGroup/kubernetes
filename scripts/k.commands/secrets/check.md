# check

Checks the local age recipient, generated SOPS configuration, and encrypted secrets.

## Description

Verifies that:

- the recipient derived from the local age key is configured in `secrets/recipients.yaml`;
- the generated configuration matches the root `.sops.yaml`; and
- every encrypted `secrets/*.yaml` file decrypts successfully with `sops`.

Each decrypted file is reported as `OK: <path>`, followed by the local
`Recipient` line.

## Usage

```
k secrets check
```

## Prerequisites

- `state.yaml` must contain the values required by the `k` dispatcher.
- `secrets/recipients.yaml`, `.sops.yaml`, and the local age key must exist.
- At least one encrypted secret YAML file must exist under `secrets/`.
- `yq`, `sops`, and `age-keygen` must be available.

## Notes

- The key path is `SOPS_AGE_KEY_FILE` when set; otherwise it is
  `${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`.
- `recipients.yaml` is excluded from the encrypted-secret scan.
- The command accepts no arguments and only creates a temporary comparison file.
