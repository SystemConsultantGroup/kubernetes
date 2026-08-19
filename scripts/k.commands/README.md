# `k` command implementation

This directory implements the command tree exposed by [`../k`](../k).
The shell files are sourced by the dispatcher, not executed as standalone
scripts.
They use shared paths, state values, validation functions, and helpers
initialized by `k`.

## Layout

- Top-level scripts implement `k apply`, `k configure`, `k install`, `k reset`,
  and dispatch.
- `configure/`, `forward/`, `generate/`, `install/`, `secrets/`, `upgrade/`, and `wait/`
  contain grouped subcommands.
- The Markdown file beside each shell script provides its user-facing help.

The dispatcher uses the first summary line of each document in command lists.
Keep the matching document current when behavior, usage, prerequisites, or
safety properties change.

## Adding a command

Add matching `.sh` and `.md` files under the appropriate path.
Reuse the existing `require_*` helpers, return usage errors for invalid
arguments, and preserve the repository-root working directory.
Add a nested directory only when a command has subcommands.

Do not duplicate dispatcher initialization or bypass shared helpers.
Test help and shell syntax from the development shell:

```bash
k --help
k <command> --help
bash -n scripts/k scripts/k.commands/<changed-command>.sh
```

Do not invoke mutating commands against a live cluster just to test their shell
behavior.
