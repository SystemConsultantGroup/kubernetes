[한국어](README.md) | English

# Operator commands

[`k`](k) is the platform-engineer entrypoint for local cluster operations. It
is not part of the application-developer workflow. Start in the repository
development shell:

```bash
nix develop
k --help
```

The shell adds `scripts/` to `PATH`, provides the repository's main tooling,
and points `TALOSCONFIG` and `KUBECONFIG` at ignored files in the repository
root. Help and encrypted-secret management do not load cluster state, so they
remain available while repairing `state.yaml`.

## Command groups

| Command | Purpose |
| --- | --- |
| `k secrets` | Validate and edit encrypted values and manage age recipients |
| `k ensure` | Validate and repair local Talos and Kubernetes credentials |
| `k render` | Render state-derived schemas and Kubernetes manifests |
| `k install` | Bootstrap Kubernetes, Cilium, and the Argo CD GitOps root |
| `k initialize` | Initialize stateful services that require privileged API calls |
| `k apply` | Apply Talos patches to every declared node |
| `k upgrade` | Upgrade Talos or Kubernetes to the version in `state.yaml` |
| `k reset` | Wipe and reboot a Talos node |
| `k wait` | Wait for Talos or Kubernetes health |
| `k forward` | Forward Argo CD to localhost |

Use `k <command> --help` immediately before an operation; each page describes
its prerequisites, arguments, side effects, and confirmation behavior. The
matching documents are in [`k.commands/`](k.commands/README.en.md).

Common safe starting points are:

```bash
k secrets check
k render application-schemas --check
k render manifests
nix flake check
```

The repository checks live under [`checks/`](checks/README.en.md). They do not access the
cluster and are not operator commands.

## Local artifacts

`k ensure talosconfig` and `k ensure kubeconfig` write local credentials at the
repository root. `k render manifests` writes inspectable, non-secret output to
`.rendered/`. These paths use local state, are ignored by Git, and must not be
copied into issues or pull requests when they contain environment details.

## Safety

`k install`, `k initialize`, `k apply`, `k upgrade`, and `k reset` can change a
live cluster. Review [`../state.yaml`](../state.yaml), node patches, and the
relevant command help first. `k reset` wipes Talos `STATE` and `EPHEMERAL` data.
