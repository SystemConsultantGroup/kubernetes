[한국어](talos.md) | English

# talos

Waits for direct Talos API access to every node in `state.yaml`, then checks cluster health against the complete declared control-plane set.

## Behavior

The command first connects directly to every declared node instead of relying
on cluster discovery through the main endpoint. It waits up to 10 minutes for
each Talos API, then passes every declared address to one `talosctl health`
check as an explicit control-plane node. This prevents an absent joining node
from being silently omitted by discovery.

The command labels health errors emitted while services are starting as
expected transient output. It returns non-zero when a direct API does not become
ready or the cluster health check fails.

## Usage

```bash
k wait talos
```

## Prerequisites

- `talosconfig` exists at the repository root; ensure it with
  `k ensure talosconfig`.
- Every node in `state.yaml` is reachable.

The command accepts no arguments and returns a non-zero status when a health
check fails.
