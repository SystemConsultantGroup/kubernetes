# talos

Upgrades Talos on every declared node to `talos.version` in `state.yaml`.

## Behavior

The command checks each node and skips nodes already at the target. If any node
needs an upgrade, it prompts once, unless `--yes` is supplied, then upgrades the
remaining nodes one at a time in `state.yaml` order with the pinned installer
image and `--wait`. It finishes with `k wait talos`.

## Usage

```bash
k upgrade talos [--yes]
```

## Prerequisites

- Every node in `state.yaml` is reachable through the repository talosconfig.
- `state.yaml` contains the target Talos version and schematic.
- The target installer image is available.

The installer image has the form
`factory.talos.dev/installer/<schematic>:<version>`. Nodes may reboot during
the upgrade; do not interrupt the one-at-a-time sequence.
