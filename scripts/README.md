# Operator commands

The [`k`](k) command is the supported entrypoint for local cluster operations.
Enter the repository development shell first:

```bash
nix develop
k --help
```

The shell adds `scripts/` to `PATH`, supplies the required tools, and sets the
repository-local `TALOSCONFIG` and `KUBECONFIG` paths.

## Command groups

| Command | Use |
| --- | --- |
| `k secrets` | Check and edit SOPS-encrypted values and manage age recipients |
| `k generate` | Generate Talos, Kubernetes, and application schema artifacts |
| `k install` | Bootstrap Kubernetes, Cilium, and Argo CD |
| `k apply` | Apply Talos patches to every declared node |
| `k upgrade` | Upgrade a component to the version in `state.yaml` |
| `k reset` | Wipe and reboot a Talos node |
| `k wait` | Wait for Talos or Kubernetes health |
| `k forward` | Forward Argo CD to localhost |

Use `k <command> --help` for prerequisites and options. The detailed help files
are in [`k.commands/`](k.commands/).

## Local artifacts

`k generate talosconfig` and `k generate kubeconfig` write client configuration
files at the repository root. They are local credentials, use mode `600`, and
are ignored by Git. Do not commit, copy, or paste them into issues or pull
requests.

## Safety

`k install`, `k apply`, `k upgrade`, and `k reset` can change a live cluster.
Review [`../state.yaml`](../state.yaml), node patches, and the relevant command
help before running them. `k reset` wipes Talos `STATE` and `EPHEMERAL` data.
