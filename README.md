# SCG Kubernetes

This repository defines application deployments and operates the single `scg`
Kubernetes cluster. The platform uses Talos Linux, Cilium, Argo CD, and
SOPS-encrypted secrets.

Argo CD follows `main`, automatically applies the declared state, and removes
resources that are no longer declared.

## Deploy an application

Application owners normally work only in [`applications/`](applications/) and
do not need cluster credentials.

An application uses one of two layouts:

- A managed application has `meta.yaml` for workload configuration and
  `instances/production.yaml` for immutable source and image versions. Testing
  and pull request preview instances are optional.
- A custom application has a standard `kustomization.yaml` entrypoint.

Use exactly one layout per application. Never commit credentials or other
secret values. Submit changes through a pull request; merging to `main` makes
them eligible for automatic deployment.

## Operate the cluster

Install Nix if needed:

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Enter the repository development environment and inspect the available
commands:

```bash
nix develop
k --help
k <command> --help
```

Operators who need access to encrypted configuration can create or inspect
their local age recipient with:

```bash
k secrets recipients me
```

An existing operator must add that recipient before `k secrets check` can
decrypt and validate the repository secrets.

Cluster-changing operations include:

```bash
k install
k apply
k upgrade <talos|kubernetes|cilium|argocd>
k reset [node]
```

> [!CAUTION]
> Review `state.yaml`, the node addresses, and disk selectors in `patches/`
> before changing the cluster. `k reset` wipes the selected node's Talos
> `STATE` and `EPHEMERAL` data.

## Repository map

- [`applications/`](applications/) contains application metadata, immutable
  deployment instances, and custom Kustomizations.
- [`argocd/`](argocd/) contains the GitOps root, ApplicationSets, platform
  components, projects, and the shared application chart.
- [`patches/`](patches/) contains shared and node-specific Talos machine
  configuration.
- [`scripts/`](scripts/) provides the `k` operator command and its built-in
  command documentation.
- [`secrets/`](secrets/) contains the public recipient registry and
  SOPS-encrypted cluster configuration.
- [`state.yaml`](state.yaml) declares cluster topology and component versions.
