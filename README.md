# SCG Kubernetes

This repository is the desired state for the single `scg` Kubernetes cluster.
It defines application deployments and the Talos, Cilium, and Argo CD platform.
Argo CD follows `main` with pruning and self-healing enabled, so merging a
change under [`applications/`](applications/) or [`argocd/`](argocd/) can change
the live cluster.

## Application owners

Work in [`applications/`](applications/) and submit a pull request.
Use exactly one layout per application:

- A managed application has `meta.yaml` and immutable files under `instances/`.
- A custom application has a root `kustomization.yaml`.

Do not mix the layouts or commit credentials.
The applications documentation covers the file formats and deployment behavior.

## Platform operators

Platform operators need Nix with flakes enabled.
If Nix is not already available, the Determinate installer is the easiest way to
set up a compatible configuration:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

If Nix is already installed, enable flakes before entering the development
shell.
Then inspect the command help:

```bash
nix develop
k --help
k <command> --help
```

The shell provides the supported tooling and points `TALOSCONFIG` and
`KUBECONFIG` at ignored files in the repository root.
Create a local age key and print its recipient:

```bash
k secrets recipients me
```

Ask an existing operator to add that recipient before checking encrypted
secrets:

```bash
k secrets check
```

The following commands can change the cluster:

```text
k install
k apply
k upgrade <talos|kubernetes|cilium|argocd>
k reset [--yes] [node]
```

> [!CAUTION]
> Review [`state.yaml`](state.yaml), node addresses, and disk selectors in
> [`patches/`](patches/) before an operation. `k reset` wipes the selected
> node's Talos `STATE` and `EPHEMERAL` partitions.

Change Argo CD-managed resources in Git, not with direct cluster edits.

## Repository map

- [`applications/`](applications/) contains application metadata, immutable
  instance locks, and custom Kustomizations.
- [`argocd/`](argocd/) contains the GitOps root, ApplicationSets, platform
  components, projects, and the shared application chart.
- [`patches/`](patches/) contains shared and node-specific Talos patches.
- [`scripts/`](scripts/) provides the `k` operator command and its help.
- [`secrets/`](secrets/) contains the public recipient registry and encrypted
  cluster configuration.
- [`state.yaml`](state.yaml) is authoritative for cluster topology and versions.
- [`workers/`](workers/) contains Cloudflare Workers deployed outside Argo CD.
