[한국어](ensure.md) | English

# ensure

Ensures that local Talos and Kubernetes credentials are current and usable.

## Usage

```bash
k ensure
k ensure <command>
```

Running `k ensure` with no subcommand ensures `talosconfig` first and then
`kubeconfig`. The kubeconfig step requires an available Kubernetes cluster, so
use the individual commands at the appropriate points during initial bootstrap.

## Subcommands

- `talosconfig` compares the local configuration with `state.yaml` and encrypted
  Talos secrets, replacing it only when missing or stale.
- `kubeconfig` retains a kubeconfig that can reach the Kubernetes API and
  retrieves a replacement through Talos otherwise.

Both files are written at the repository root with mode `600` and ignored by
Git. These commands do not change cluster resources.
