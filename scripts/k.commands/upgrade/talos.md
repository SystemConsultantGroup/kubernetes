# talos

Upgrades Talos OS on every node to the version pinned in state.yaml.

## Description

For each node in state.yaml, compares the running Talos version
(`talosctl version --short`) with the `talos.version` pinned in state.yaml.
Nodes already on the target version are reported and skipped. If any node
needs an upgrade, prompts for confirmation (or applies with `--yes`), then
runs `talosctl upgrade` per node with the pinned installer image and
`--wait`, and finally waits for Talos and Kubernetes health on every node
(`k wait talos`).

## Prerequisites

- Nodes reachable from the repo-root talosconfig.
- state.yaml pins the Talos version and schematic.

## Usage

```
k upgrade talos [--yes]
```

## Notes

- The installer image is `factory.talos.dev/installer/<schematic>:<version>` from state.yaml.
- Nodes are upgraded one at a time, in state.yaml order.
