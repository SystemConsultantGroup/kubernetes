# cilium

Upgrades Cilium to `cilium.version` in `state.yaml`.

## Behavior

The command reads the installed `cilium` Helm release in `kube-system`.
If its chart version already matches, it exits without changes.
Otherwise it prompts, unless `--yes` is supplied, reapplies the pinned Gateway
API standard release, and runs:

```text
cilium upgrade --version <target> --wait --wait-duration 10m
```

## Usage

```bash
k upgrade cilium [--yes]
```

## Prerequisites

- The `cilium` Helm release exists in `kube-system`.
- `state.yaml` contains `cilium.version` and `gateway-api.version`.
- The cluster and the Cilium CLI are reachable and available.

The command fails when the Cilium release is not found.
