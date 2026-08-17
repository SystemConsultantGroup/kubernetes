# ApplicationSets

These ApplicationSets turn paths in `main` into Argo CD Applications. They are
included by [`../kustomization.yaml`](../kustomization.yaml) and generate
Applications in the `applications` AppProject.

## Generators

| Resource | Files discovered | Result |
| --- | --- | --- |
| `application-instances-static` | `applications/*/instances/production.yaml` and `testing.yaml` | Shared application chart |
| `application-instances-dynamic` | `applications/*/instances/preview/*/*.yaml` | Shared chart with one preview workload |
| `application-kustomize` | `applications/*/kustomization.yaml` | Application directory rendered directly |

Managed metadata and stable instance locks are passed to the shared chart as
separate values files. A preview lock supplies only `source` and `image`; its
workload and pull request number come from the path.

Generated names and namespaces are deterministic:

- stable managed instances use `app-<instance>-<application>`;
- previews use `app-preview-<application>-<workload>-<pull-request>`; and
- custom applications use `app-<application>`.

Each generated Application enables automated sync, pruning, self-healing, and
namespace creation. Application namespaces receive the labels required for
public Gateway routes and restricted pod security.

## Editing rules

- Keep each application in one layout; do not let two generators discover the
  same path.
- Preserve the repository URL and `main` revision unless the GitOps policy
  changes deliberately.
- Treat generator, project, namespace, and sync-policy changes as platform-wide
  changes.

See [`../projects/README.md`](../projects/README.md) for the permissions of the
`applications` AppProject.
