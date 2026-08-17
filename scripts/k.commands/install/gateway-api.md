# gateway-api

Installs the pinned Kubernetes Gateway API standard CRDs.

## Behavior

Applies `standard-install.yaml` for `gateway-api.version` in `state.yaml` with
server-side apply. The manifest is fetched from the Kubernetes Gateway API
GitHub release.

## Usage

```bash
k install gateway-api
```

## Prerequisites

- The cluster is reachable through the repository kubeconfig.
- `state.yaml` contains `gateway-api.version`.
- Network access to the Gateway API GitHub release is available.

The command accepts no arguments and changes cluster-scoped resources.
