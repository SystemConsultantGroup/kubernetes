# kubeconfig

Ensures usable local Kubernetes credentials.

## Behavior

When the existing `kubeconfig` can authenticate and check namespace access
within five seconds, the command retains it and enforces mode `600`. Otherwise it asks
the main Talos node for a replacement, verifies the replacement against the
Kubernetes API, and installs it atomically without merging another kubeconfig.

## Usage

```bash
k ensure kubeconfig
```

## Prerequisites

- `talosconfig` exists and contains valid credentials; use
  `k ensure talosconfig` first.
- The main Talos node and Kubernetes API are reachable.

The command accepts no arguments and does not change cluster resources.
