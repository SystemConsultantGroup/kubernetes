# kubernetes

Upgrades the Kubernetes control plane to the version pinned in state.yaml.

## Description

Compares the server version reported by `kubectl version` with the
`kubernetes.version` pinned in state.yaml. If they match, prints the current
version and exits without changes. Otherwise runs `talosctl upgrade-k8s
--dry-run` against the main node, prompts for confirmation (or applies with
`--yes`), applies the upgrade with `talosctl upgrade-k8s`, and finally waits
for Talos and Kubernetes health on every node (`k wait talos`).

## Prerequisites

- Cluster reachable via the repo-root kubeconfig.
- state.yaml pins `kubernetes.version`.
- Talos supports the target Kubernetes version.

## Usage

```
k upgrade kubernetes [--yes]
```

## Notes

- Runs against the main node only (`MAIN_IP` from state.yaml).
- The dry-run must succeed before the confirmation prompt appears.
