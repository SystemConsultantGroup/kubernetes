# generate

Generates client configuration files and the application chart schema.

## Commands

- `application-schemas` generates or checks the committed chart schema.
- `kubeconfig` writes the cluster kubeconfig.
- `talosconfig` writes the Talos client configuration.

## Usage

```text
k generate <command> [args...]
```

Running `k generate` lists subcommands.
Use `k generate --help` for this page.
Each subcommand documents its own prerequisites.

## Common outputs

The client configuration commands overwrite repository-root `kubeconfig` or
`talosconfig` files and set mode `600`.
These files are local credentials and are ignored by Git.
The schema command can check committed output without modifying it:

```bash
k generate application-schemas --check
```
