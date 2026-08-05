# Talos cluster

Declarative configuration and a small `t` CLI for provisioning and maintaining the `scg` Talos Kubernetes cluster.

The repository manages Talos machine configuration, Cilium networking, Argo CD bootstrap, and SOPS-encrypted secrets. Cluster state is declared in [`state.yaml`](state.yaml); generated client configurations stay local.

## Requirements

Install [Devbox](https://www.jetify.com/devbox/) and enter the project shell:

```bash
devbox shell
```

Devbox provides `talosctl`, `kubectl`, `cilium`, Helm, SOPS, age, and `yq`. It also adds `scripts/` to `PATH`, sets project-local `TALOSCONFIG` and `KUBECONFIG` paths, and loads Bash completion for `t`.

## Configuration

[`state.yaml`](state.yaml) is the public source of truth for cluster versions and nodes:

```yaml
name: scg
endpoint: scc

talos:
  version: "1.13.7"
  schematic: "..."

kubernetes:
  version: "1.36.2"

cilium:
  version: "1.19.6"

argocd:
  version: "10.2.2" # chart version

nodes:
  scc:
    address: "115.145.134.232"
```

Talos versions omit the `v` prefix; `t` adds it when invoking Talos tools. `endpoint` names the node used for the Kubernetes API and bootstrap operations.

Each configured node requires a matching `patches/<name>.yaml`. The current apply flow generates every configured node as a control plane and applies:

- `patches/<name>.yaml` — node-specific disk and hostname settings
- `patches/worker.yaml` — enables workload scheduling on control planes
- `patches/cilium.yaml` — Talos configuration required by Cilium

Generated `talosconfig` and `kubeconfig` files are project-local, mode `600`, and ignored by Git.

## Secrets

Encrypted secret files live under `secrets/`:

| File | Purpose |
| --- | --- |
| `secrets/talos.yaml` | Talos PKI and machine secrets |
| `secrets/env.yaml` | Argo CD, Cloudflare, and DNS credentials |
| `secrets/state.yaml` | Public age recipient aliases; not encrypted |

`.sops.yaml` is generated from `secrets/state.yaml`. It includes every `secrets/*.yaml` file except `secrets/state.yaml`.

### Local age identity

Create or display your local identity:

```bash
t secrets recipient me
```

The private key defaults to `~/.config/sops/age/keys.txt`. The command prints the corresponding public `age1...` recipient.

A new operator cannot grant their own key access. Send the printed recipient to an existing operator, who runs:

```bash
t secrets recipient add alice-laptop age1...
```

Recipient aliases should identify a person and device so one compromised device can be revoked independently.

### Recipient management

```bash
t secrets recipient me
t secrets recipient list
t secrets recipient add <name> <age1...>
t secrets recipient remove <name>
```

Adding or removing a recipient regenerates `.sops.yaml` and rekeys every encrypted file. The operation restores the previous files if rekeying fails. Duplicate aliases and recipients are rejected, and the final recipient cannot be removed.

Validate recipient state and decryptability:

```bash
t secrets check
```

Edit an encrypted file by its discovered name:

```bash
t edit env
t edit talos
```

`t edit` discovers `secrets/*.yaml` dynamically and excludes `state.yaml`. Plaintext is handled by SOPS and is never written to a tracked file.

The bootstrap environment currently recognizes:

- `ARGOCD_GITHUB_CLIENT_SECRET`
- `CLOUDFLARE_API_TOKEN`
- `RFC2136_TSIG_SECRET`

The first two are required by `t setup` and `t install argocd`.

## Provisioning

For a fresh or reset Talos node:

```bash
t secrets check
t setup
```

`t setup` runs, in order:

1. Generate `talosconfig` from encrypted Talos secrets.
2. Generate and apply control-plane configuration to every node.
3. Bootstrap etcd, retrying for up to ten minutes; initialized etcd is skipped.
4. Wait for Talos and Kubernetes health.
5. Generate the project-local kubeconfig.
6. Install Gateway API CRDs and Cilium.
7. Install Argo CD and apply the root application.

`t apply` automatically uses the authenticated Talos API for configured nodes and insecure maintenance mode for fresh nodes.

### Reset

Reset the endpoint node or a named node from `state.yaml`:

```bash
t reset
t reset scc
```

Reset wipes Talos `STATE` and `EPHEMERAL` data and asks for confirmation. For unattended operation:

```bash
t reset --yes scc
```

## Upgrades

Change the desired version in `state.yaml`, then run the matching command:

```bash
t upgrade talos
t upgrade kubernetes
t upgrade cilium
t upgrade argocd
```

Use `--yes` to skip confirmation. Each command checks the installed version and exits without changes when already current.

- **Talos** upgrades nodes sequentially with the configured factory image, then checks cluster health.
- **Kubernetes** prints Talos's dry-run upgrade plan before confirmation, applies it, then checks health.
- **Cilium** uses `cilium upgrade` and waits up to ten minutes.
- **Argo CD** upgrades the pinned Helm chart with the existing values and bootstrap secrets.

A conservative upgrade order is Talos, Kubernetes, Cilium, then Argo CD, checking cluster health between components.

## Command reference

### Cluster lifecycle

| Command | Description |
| --- | --- |
| `t setup` | Provision a fresh cluster and install Cilium and Argo CD |
| `t apply` | Generate and apply machine configuration to all declared nodes |
| `t bootstrap` | Bootstrap etcd, or exit when it is already initialized |
| `t reset [--yes] [node]` | Destructively reset a node |

### Generated access files

| Command | Description |
| --- | --- |
| `t generate talosconfig` | Generate the project-local Talos client configuration |
| `t generate kubeconfig` | Download the project-local Kubernetes configuration |

### Installation and health

| Command | Description |
| --- | --- |
| `t install cilium` | Install Gateway API CRDs and Cilium on a fresh cluster |
| `t install argocd` | Install or reconcile Argo CD, credentials, and the root application |
| `t wait talos` | Wait for Talos and Kubernetes control-plane health |
| `t wait kubernetes [component]` | Wait up to ten minutes for all pods in all namespaces to become Ready |
| `t forward argocd` | Forward Argo CD to `http://localhost:8080` |

### Secrets and upgrades

```text
t edit <secret>
t secrets check
t secrets recipient me
t secrets recipient list
t secrets recipient add <name> <age1...>
t secrets recipient remove <name>
t upgrade <talos|kubernetes|cilium|argocd> [--yes]
```

Run `t --help` or `t <group> --help` to discover commands. Bash completion follows the nested command tree and dynamically completes secret names, recipient aliases, and node names.

## Repository layout

```text
state.yaml                    Cluster versions, endpoint, and nodes
patches/                      Talos machine configuration patches
secrets/                      Encrypted values and public recipient state
scripts/t                     CLI entry point and shared helpers
scripts/commands/             Dynamically discovered command modules
scripts/completions/t.bash    Bash completion
devbox.json                   Reproducible local tool environment
```

Do not commit plaintext secrets, `talosconfig`, or `kubeconfig`.
