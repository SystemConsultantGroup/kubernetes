[한국어](README.md) | English

# Repository checks

These checks validate repository contracts without accessing a live cluster.
Run the complete pinned suite from the repository root:

```bash
nix flake check
```

| Area | What is checked |
| --- | --- |
| Shell | Bash syntax and ShellCheck for the dispatcher and command sources |
| Documentation | Local Markdown links, excluding intentionally untracked sensitive appendices |
| State | Repeated platform pins match `state.yaml` |
| Applications | One layout, exact lock fields, workload consistency, preview paths, identity limits, and namespace boundaries |
| Rendering | Root and platform Kustomizations, every managed instance, and synthetic long-name collision cases |
| Worker | Vault KMS compatibility tests |

Keep checks deterministic, credential-free, and safe without kubeconfig or
talosconfig. Network-dependent schema generation and Wrangler checks remain
explicit validation steps documented in [`../../AGENTS.md`](../../AGENTS.md).
