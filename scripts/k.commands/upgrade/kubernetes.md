# kubernetes

Upgrades the Kubernetes control plane to `kubernetes.version` in `state.yaml`.

## Behavior

The command compares the Kubernetes server version with the target.
If they match, it exits without changes.
Otherwise it runs a Talos dry run against the main node, prompts, unless `--yes`
is supplied, applies the upgrade against that node, and waits for Talos and
Kubernetes health on every declared node.
The dry run must succeed before the prompt appears.

## Usage

```bash
k upgrade kubernetes [--yes]
```

## Prerequisites

- The cluster is reachable through the repository kubeconfig.
- `talosconfig` can reach the main node selected by `state.yaml`.
- `state.yaml` contains `kubernetes.version`.
- Talos supports the target Kubernetes version.

The command does not change `state.yaml`; update and review the pinned version
before running it.
