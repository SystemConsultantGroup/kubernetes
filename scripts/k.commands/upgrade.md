# upgrade

Upgrades Argo CD, Cilium, Kubernetes and Talos to the versions pinned in state.yaml.

## Description

Runs the subcommand for the given component. Each subcommand compares the
currently installed version with the version pinned in state.yaml, reports
when nothing needs to change, otherwise prompts for confirmation (or applies
with `--yes`) and performs the upgrade.

## Prerequisites

- A working cluster; Talos and Kubernetes upgrades need talosctl access to the nodes.
- The target version is bumped first in state.yaml.

## Usage

```
k upgrade <command> [--yes]
```

## Subcommands

- `argocd` — upgrades the Argo CD Helm chart to the version pinned in state.yaml
- `cilium` — upgrades Cilium to the version pinned in state.yaml
- `kubernetes` — upgrades the Kubernetes control plane to the version pinned in state.yaml
- `talos` — upgrades Talos OS on every node to the version pinned in state.yaml

## Notes

- `k upgrade` with no argument lists the available subcommands.
- Each subcommand prompts `[y/N]` unless `--yes` is passed.
