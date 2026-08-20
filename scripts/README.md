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
| `k generate` | Generate Talos, Kubernetes, and application schema artifacts |
| `k install` | Bootstrap Kubernetes, Cilium, and Argo CD |
| `k apply` | Apply Talos patches to every declared node |
| `k upgrade` | Upgrade a component to the version in `state.yaml` |
| `k reset` | Wipe and reboot a Talos node |
| `k wait` | Wait for Talos or Kubernetes health |
| `k forward` | Forward Argo CD to localhost |

Use `k <command> --help` for prerequisites, arguments, and side effects.
The matching documents are in [`k.commands/`](k.commands/). Internal repository
checks live under [`checks/`](checks/) and run through `nix flake check`; they
are not operator commands.

## Local credentials

`k generate talosconfig` and `k generate kubeconfig` write client configuration
files at the repository root.
They use mode `600` and are ignored by Git.
Do not commit, copy, or paste them into issues or pull requests.

## Safety

`k install`, `k apply`, `k upgrade`, and `k reset` can change a live cluster.
Review [`../state.yaml`](../state.yaml), node patches, and the relevant command
help first. `k reset` wipes Talos `STATE` and `EPHEMERAL` data.
