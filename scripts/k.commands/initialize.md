# initialize

Performs privileged service initialization around the GitOps lifecycle.

## Commands

- `monitoring` materializes Grafana's Dex client and stable administrator
  Secrets before the monitoring resources reconcile, or rotates them later.
- `vault` initializes fresh Vault storage and configures privileged APIs, or
  reconciles configuration while a valid bootstrap root token remains.

## Usage

```bash
k initialize <command>
```

Running `k initialize` lists subcommands. Initialization changes live state and
is intentionally separate from `k install`, which stops after bootstrapping the
Argo CD root.
