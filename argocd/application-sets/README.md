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

## Generated identities

The application name is the first component of every generated identity.

| Application type | Argo CD Application | Helm release | Destination namespace |
| --- | --- | --- | --- |
| production | `<application>-production` | `<application>-production` | `<application>-production` |
| testing | `<application>-testing` | `<application>-testing` | `<application>-testing` |
| preview | `<application>-preview-<workload>-<pull-request>` | same | same |
| custom Kustomize | `<application>` | none | `<application>` |

The Argo CD Application objects themselves live in the `argocd` namespace.
Managed application resource names are documented in
[`../charts/application/README.md`](../charts/application/README.md).

Renaming an Application or destination namespace changes Argo CD identity and
can cause the old Application and namespace to be pruned before the new ones
are reconciled. Treat naming changes as live migration work and review the
expected deletion and recreation behavior before merging.

## Editing rules

- Keep each application in one layout; do not let two generators discover the
  same path.
- Preserve the repository URL and `main` revision unless the GitOps policy
  changes deliberately.
- Treat generator, project, namespace, and sync-policy changes as platform-wide
  changes.

Each generated Application enables automated sync, pruning, self-healing, and
namespace creation. Application namespaces receive the labels required for
public Gateway routes and restricted pod security.

See [`../projects/README.md`](../projects/README.md) for the permissions of the
`applications` AppProject.
