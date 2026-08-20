# initialize

Performs privileged post-GitOps service initialization.

## Commands

- `vault` initializes fresh Vault storage and configures privileged APIs, or
  reconciles configuration while a valid bootstrap root token remains.

## Usage

```bash
k initialize <command>
```

Running `k initialize` lists subcommands. Initialization changes live state and
is intentionally separate from `k install`, which stops after bootstrapping the
Argo CD root.
