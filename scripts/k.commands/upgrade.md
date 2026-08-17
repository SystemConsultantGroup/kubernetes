# upgrade

Upgrades a component to the version already pinned in `state.yaml`.

## Subcommands

- `argocd` upgrades the Argo CD Helm chart.
- `cilium` upgrades Cilium and reapplies the Gateway API release.
- `kubernetes` upgrades the Kubernetes control plane.
- `talos` upgrades Talos on every declared node.

## Usage

```bash
k upgrade <command> [--yes]
```

Running `k upgrade` lists subcommands.
Set and review the target version in `state.yaml` before running an upgrade; the
command does not edit that file.
Each subcommand checks the installed version and exits without changes when it
already matches.

## Prerequisites

- Run inside `nix develop`.
- The target component is installed and the cluster is reachable.
- Talos and Kubernetes upgrades have valid Talos access to the nodes.
- Any component-specific secrets or files required by its install command exist.

Unless `--yes` is supplied, an upgrade prompts with `[y/N]`.
Treat `--yes` as a reviewed automation option: upgrades change a live cluster
and may reboot nodes.
