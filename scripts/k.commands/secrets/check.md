# check

Checks the local age recipient, generated SOPS configuration, and encrypted
secret files.

## Behavior

The command verifies that:

- the recipient derived from the local age key is in `secrets/state.yaml`;
- `.sops.yaml` matches the generated configuration; and
- every encrypted top-level `secrets/*.yaml` file decrypts successfully.

It prints `OK: <path>` for each decrypted file and the local `Recipient` at the
end. `secrets/state.yaml` itself is excluded from the encrypted-file scan.

## Usage

```bash
k secrets check
```

## Prerequisites

- Run inside `nix develop`.
- `secrets/state.yaml`, `.sops.yaml`, and the local age key exist.
- At least one encrypted YAML file exists under `secrets/`.
- The local recipient has already been added to the recipient map.

The key path is `SOPS_AGE_KEY_FILE` when set; otherwise it is
`${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`.
The command accepts no arguments and only creates a temporary comparison file.
