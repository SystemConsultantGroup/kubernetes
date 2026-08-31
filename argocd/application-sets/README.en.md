[한국어](README.md) | English

# ApplicationSets

These ApplicationSets turn paths in `main` into Argo CD Applications.
They are included by [`../kustomization.yaml`](../kustomization.yaml). Workload
Applications use the `applications` AppProject; generated ingress-policy
Applications use the `platform` AppProject so application layouts cannot create
cluster-scoped policy resources directly.

## Generators

| Resource | Files discovered | Result |
| --- | --- | --- |
| `application-instances-static` | `applications/*/instances/production.yaml` and `testing.yaml` | Shared application chart |
| `application-instances-dynamic` | `applications/*/instances/preview/*/*.yaml` | Shared chart with one preview workload |
| `application-routing-policies` | `applications/*/meta.yaml` | Exact public-host policy for managed production domains |
| `application-kustomize` | `applications/*/kustomization.yaml` | Application directory rendered directly |

Managed metadata and stable instance locks are passed to the shared chart as
separate values files.
A preview lock supplies only `source` and `image`; its workload and pull request
number come from the path.

The managed generators own the enabled central Vault integration gate and its
trusted server URL. Application metadata does not control this gate or provide
Vault paths. The contract and activation procedure are documented in the
[Vault component README](../platform/vault/README.en.md).

## Refresh behavior

GitHub push webhooks refresh the Argo CD API server and the ApplicationSet
controller immediately.
The two controllers use separate webhook paths.
Git polling remains enabled at 180 seconds as a fallback when a webhook is
delayed or unavailable.

## Generated identities

The application name is the first component of every generated identity.

| Application type | Argo CD Application | Helm release | Destination namespace |
| --- | --- | --- | --- |
| production | `<application>-production` | `<application>-production` | `<application>-production` |
| testing | `<application>-testing` | `<application>-testing` | `<application>-testing` |
| preview | `<application>-preview-<workload>-<pull-request>` | same | same |
| production ingress policy | `ingress-<application>` | same | `gateway-system` |
| custom Kustomize | `<application>` | none | `<application>` |

The Argo CD Application objects themselves live in the `argocd` namespace.
Repository checks reject identities that exceed Kubernetes name limits before
ApplicationSet reconciliation. Managed application resource names are documented in
[`../charts/application/README.en.md`](../charts/application/README.en.md).

Renaming an Application or destination namespace changes Argo CD identity and
can cause the old Application and namespace to be pruned before the new ones are
reconciled.
Treat naming changes as live migration work and review the expected deletion and
recreation behavior before merging.

## Editing rules

- Keep each application in one layout; do not let two generators discover the
  same path.
- Preserve the repository URL and `main` revision unless the GitOps policy
  changes deliberately.
- Treat generator, project, namespace, and sync-policy changes as platform-wide
  changes.

Each generated Application enables automated sync, pruning, self-healing, and
namespace creation. Managed Applications ignore Reloader's pod-template
annotation so a Secret-triggered rolling deployment does not conflict with Argo
CD self-healing.
Application namespaces receive the labels required for public Gateway routes and
restricted pod security.

See [`../projects/README.en.md`](../projects/README.en.md) for the permissions of the
`applications` AppProject.
