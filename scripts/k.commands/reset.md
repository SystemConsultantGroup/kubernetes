# reset

Wipes a Talos node's `STATE` and `EPHEMERAL` partitions, then reboots it.

> [!CAUTION]
> This is destructive.
> Node-local data in both selected system partitions is lost, and the node
> reboots. Confirm the node name and the intended recovery procedure first.

## Behavior

Without a node argument, the command targets the main node selected by
`.endpoint` in `state.yaml`.
With a node argument, it requires that node name to be declared in `state.yaml`.
It runs `talosctl reset` with a non-graceful reset and wipes only the `STATE`
and `EPHEMERAL` system labels. Separately declared Talos user volumes are not
targeted by this command. SCC's `local-data` path is on its separate `data` user
volume, but always verify each target node's live storage before reset.

The command prompts for confirmation unless `--yes` is supplied.
It runs `k ensure talosconfig` before resetting so local credentials match the
declared cluster.

## Usage

```bash
k reset [--yes] [node]
```

## Prerequisites

- The target node is declared in `state.yaml`.
- `secrets/talos.yaml` is decryptable so `talosconfig` can be ensured.
- The target is reachable with the Talos client configuration.

`--yes` is intended for an explicitly reviewed, automated operation; it only
skips the confirmation prompt.
