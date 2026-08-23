[한국어](manifests.md) | English

# manifests

Renders state-derived Kubernetes manifests without applying them.

## Output

The command atomically recreates the ignored `.rendered/` directory:

| Path | Contents |
| --- | --- |
| `bootstrap/gateway-api.yaml` | Pinned Gateway API standard CRDs |
| `bootstrap/cilium.yaml` | Pinned Cilium chart and shared Talos-compatible values |
| `bootstrap/argocd.yaml` | Pinned Argo CD chart and repository values |
| `gitops/root.yaml` | Root Argo CD Kustomization |
| `gitops/platform/` | Repository-local platform Kustomizations |
| `applications/` | Every custom and managed application instance |

Bootstrap rendering uses component versions from `state.yaml`. GitOps
Applications repeat remote revisions because Argo CD reads the repository
without the operator command; repository checks require those revisions to
match `state.yaml`.

## Usage

```bash
k render manifests
```

## Prerequisites

- Run inside `nix develop`.
- Network access to GitHub and the Cilium and Argo CD Helm repositories is
  available.
- Application and platform source files are locally renderable.

The command accepts no arguments. It may replace `.rendered/`, which is local,
ignored output. It does not use cluster credentials or change the cluster.
