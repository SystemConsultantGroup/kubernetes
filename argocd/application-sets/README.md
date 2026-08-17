# ApplicationSets

These ApplicationSets turn repository paths into Argo CD Applications. They
are included by [`../kustomization.yaml`](../kustomization.yaml) and reconcile
from the repository's `main` branch.

## Generators

| Resource | Discovers | Rendering |
| --- | --- | --- |
| `application-instances-static` in `instances.yaml` | `applications/*/instances/production.yaml` and `testing.yaml` | The shared application Helm chart |
| `application-instances-dynamic` in `instances.yaml` | `applications/*/instances/preview/*/*.yaml` | The shared chart with one preview workload |
| `application-kustomize` in `kustomize.yaml` | `applications/*/kustomization.yaml` | The application directory directly |

Managed application metadata and stable instance locks are passed to the
shared chart as separate values files. Preview identity comes from the path;
the preview file supplies only its workload lock.

All generated Applications use automated sync, pruning, self-healing, and
managed namespaces. A custom application receives an `app-<application>`
namespace. Stable and preview managed applications use names that include their
instance identity.

## Editing rules

- Preserve the exact discovery patterns unless the application layout changes
  deliberately.
- Keep the repository URL and target revision aligned with the GitOps policy.
- Do not add a second ApplicationSet that discovers the same path.
- Treat generator, namespace, project, and sync-policy changes as platform-wide
  changes.

The generated Applications belong to the `applications` AppProject. See
[`../projects/README.md`](../projects/README.md) for its permissions.
