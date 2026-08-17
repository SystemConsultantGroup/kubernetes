# cilium

Upgrades Cilium to the version pinned in state.yaml.

## Description

Reads the installed chart version via `helm list` in the `kube-system`
namespace and compares it to the `cilium.version` pinned in state.yaml. If
they match, prints the current version and exits without changes. Otherwise
prompts for confirmation (or applies with `--yes`), runs `k install gateway-api` to keep the Gateway API in sync, then `cilium upgrade` at the
pinned version with `--wait --wait-duration 10m`.

## Prerequisites

- Cilium installed as a Helm release named `cilium` in the `kube-system` namespace.
- state.yaml pins `cilium.version`.

## Usage

```
k upgrade cilium [--yes]
```

## Notes

- Fails if the `cilium` Helm release is not found.
