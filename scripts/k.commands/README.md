# `k` command implementation

This directory implements the command tree exposed by [`../k`](../k). The
shell files are sourced by the dispatcher, not run as independent scripts.
They use shared paths, state values, validation functions, and command helpers
initialized by `k`.

## Layout

- Top-level scripts implement `k apply`, `k install`, `k reset`, and grouped
  command dispatch.
- `forward/`, `generate/`, `install/`, `secrets/`, `upgrade/`, and `wait/`
  contain grouped subcommands.
- A Markdown file next to each shell script supplies its user-facing help.

The dispatcher also uses the first summary line of a command document when it
prints command lists. Keep the matching `.md` file current whenever a command's
behavior, usage, prerequisites, or safety properties change.

## Adding a command

For a new command, add the matching `.sh` and `.md` files in the appropriate
path. Follow the existing `require_*` validation helpers, return usage errors
for invalid arguments, and preserve the repository-root working directory.
Add a nested directory only when the command has subcommands.

Do not duplicate the dispatcher or bypass its shared initialization. Test help
and shell syntax from the development shell:

```bash
k --help
k <command> --help
bash -n scripts/k scripts/k.commands/<changed-command>.sh
```

Do not invoke mutating commands against a live cluster merely to test their
shell behavior.
