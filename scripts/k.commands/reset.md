# reset

Wipes a Talos node's `STATE` and `EPHEMERAL` partitions, then reboots it.

> [!CAUTION]
> This is destructive.
> Node-local data in both partitions is lost, and the node reboots.
> Confirm the node name and the intended recovery procedure first.

## Behavior

Without a node argument, the command targets the main node selected by
`.endpoint` in `state.yaml`.
With a node argument, it requires that node name to be declared in `state.yaml`.
It runs `talosctl reset` with a non-graceful reset and wipes only the `STATE`
and `EPHEMERAL` system labels.

The command prompts for confirmation unless `--yes` is supplied.
If `talosconfig` is missing, it generates one with `k generate talosconfig`
before resetting the node.

## Usage

```bash
k reset [--yes] [node]
```

## Prerequisites

- The target node is declared in `state.yaml`.
- `talosconfig` exists or `secrets/talos.yaml` is decryptable so it can be
  generated.
- The target is reachable with the Talos client configuration.

`--yes` is intended for an explicitly reviewed, automated operation; it only
skips the confirmation prompt.
