# Repository checks

These internal checks validate repository contracts without accessing a live
cluster. `nix flake check` runs `repository.sh` with pinned tools.

The check syntax-checks and statically analyzes shell sources, checks local
Markdown links, verifies platform version pins against `state.yaml`, renders
local Kustomizations and every managed instance. It rejects mixed application
layouts,
missing production locks, inconsistent workload sets, invalid preview paths,
oversized generated identities, and duplicate rendered resources.

Keep checks deterministic, free of credentials, and safe to run without a
kubeconfig or talosconfig. Network-dependent generated-schema and Wrangler
checks remain explicit validation steps documented in `AGENTS.md`.
