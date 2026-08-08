# reset

Wipes a node's STATE and EPHEMERAL partitions and reboots it.

## Description

Resets a Talos node with `talosctl reset --graceful=false --reboot`, wiping
the STATE and EPHEMERAL system partitions. Targets the main node
(`.endpoint` in `state.yaml`) unless a node name is given; the name must exist
under `.nodes` in `state.yaml`. Without `--yes` the command prompts for
confirmation.

## Usage

```
k reset [--yes] [node]
```

## Prerequisites

- `talosconfig` at the repo root. If missing, it is generated on the spot with
  `k generate talosconfig`, which needs a sops-decryptable `secrets/talos.yaml`.

## Notes

- Destructive: all data on STATE and EPHEMERAL partitions is lost.
- The node reboots as part of the reset.
- `--yes` skips the confirmation prompt.
