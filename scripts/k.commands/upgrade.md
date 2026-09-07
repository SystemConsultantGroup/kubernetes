# upgrade

Upgrades a Talos-managed component to the version pinned in `state.yaml`.

## Subcommands

- `kubernetes` upgrades the Kubernetes control plane.
- `talos` upgrades Talos on every declared node.

## Usage

```bash
k upgrade <kubernetes|talos> [--yes]
```

Cilium, Gateway API, Argo CD, and other platform components are Argo CD desired
state. Upgrade them by changing `state.yaml` and the matching GitOps revision in
one pull request; repository checks reject mismatched pins.

The imperative Talos and Kubernetes commands check installed versions and exit
without changes when already current. Unless `--yes` is supplied, they prompt
with `[y/N]`. Treat `--yes` as a reviewed automation option because upgrades may
reboot nodes.
