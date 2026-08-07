# SCG Application Platform Design

Status: brainstormed design, not yet implemented. This document preserves decisions and open questions so work can continue in a later session.

## Current implementation baseline

Today, `argocd/applicationsets/applications.yaml` discovers `applications/*` directories and deploys their in-repository Kustomizations directly. `applications/hello-world/` contains four workload/routing manifests, and the README documents that directory-as-namespace model. The current `scg` AppProject is broad, namespaces are only created through `CreateNamespace=true`, and the shared Gateway and cert-manager manifests contain static hello-world listeners and certificates.

Implementing this proposal therefore requires an explicit migration rather than adding metadata beside the current generator:

1. Add and validate the generic chart and metadata schema.
2. Add replacement stable/preview ApplicationSets and restrictive AppProjects.
3. Add managed namespace labels and ListenerSet platform support.
4. Migrate hello-world to `meta.yaml` and remove its old manifests only after end-to-end validation.
5. Update the README when the new generator becomes authoritative.

## Goal

Make `applications/*` a small application registry rather than a collection of Kubernetes manifests. Ordinary applications should provide only identity and values that cannot be inferred. Cluster policy, environment generation, routing, TLS, and workload defaults should be centralized.

All deployable software is treated as one of:

1. **Application** — an HTTP workload using the generic application chart.
2. **Platform component** — shared cluster infrastructure under `argocd/platform/`, managed by the existing platform ApplicationSet.

Legacy `*-config` repositories are references for discovering real requirements only. They will not be used as deployment sources or migrated as-is.

## Repository layout

```text
applications/
  hello-world/
    meta.yaml
    routes/                 # absent unless custom routing is needed
      kustomization.yaml
      *.yaml
argocd/
  applicationsets/
  charts/
    application/
      Chart.yaml
      values.yaml
      templates/
  platform/
```

The generic chart belongs at `argocd/charts/application` because it is cluster policy instantiated by Argo CD. It is not an application-owned product chart.

## Application registration

The directory name is the application name. Required metadata is intentionally limited to values that cannot be inferred:

```yaml
repository: SystemConsultantGroup/kubernetes-hello-world
domain: hello.world.scg.sh
```

`repository` is always the full GitHub `owner/repository` identifier, not a URL and not a legacy `*-config` repository.

Derived values:

| Value | Derivation |
| --- | --- |
| Application name | `meta.yaml` parent-directory basename |
| Git URL | `https://github.com/<repository>.git` |
| Default image | `ghcr.io/<lowercase repository>` |
| Production hostname | `<domain>` |
| Staging hostname | `staging.<domain>` |
| PR hostname | `preview-<number>.<domain>` |
| Production namespace | `<application>` |
| Staging namespace | `<application>-staging` |
| PR namespace | `<application>-preview-<number>` |

Example with demonstrated deviations:

```yaml
repository: SystemConsultantGroup/example
domain: example.scg.sh
port: 3000
healthPath: /healthz
replicas:
  production: 3
  staging: 2
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    memory: 512Mi
env:
  LOG_LEVEL: info
envFromSecrets:
  - example-config
```

## Proposed metadata schema

Required:

- `repository`: full GitHub `owner/repository` identifier.
- `domain`: canonical production hostname.

Optional deviations:

| Field | Default | Meaning |
| --- | --- | --- |
| `image` | `ghcr.io/<lowercase repository>` | Override only the image repository; tags/digests remain automated. |
| `port` | `8080` | Container port; Service port remains `80`. |
| `healthPath` | `/` | HTTP readiness probe path. |
| `routePath` | `/` | Default HTTPRoute path prefix. |
| `replicas.production` | `1` | Production replicas. |
| `replicas.staging` | `1` | Staging replicas; previews remain fixed at one. |
| `resources` | central chart defaults | CPU/memory requests and limits. |
| `env` | none | Non-secret environment variables. |
| `envFromSecrets` | none | Existing same-namespace Secrets imported through `envFrom`; the chart does not create secret values. |
| `route` | `generated` | Set to `custom` to disable the generated HTTPRoute and load `routes/`. |

Unknown fields should fail validation once the new generator is implemented. The current repository has no application metadata schema or validator; implementation must add one before migration. Do not initially expose namespaces, image tags, hostnames, TLS, labels, pod security contexts, image pull policy, commands, arbitrary annotations, volumes, node selection, affinity, or tolerations. Add a capability only when an active application proves it is required.

## Generic `application` chart

The first chart version represents one image and one HTTP Service. It should render:

- Deployment
- Service
- HTTPRoute unless `route: custom`
- Per-application ListenerSet from the production release only
- Standard labels
- Restricted container and pod security defaults
- Readiness probe
- Resource defaults

The generated Argo CD Applications create namespaces with `CreateNamespace=true` and apply required labels through `syncPolicy.managedNamespaceMetadata`, including the Gateway selector and Pod Security Admission labels. The chart should not create Namespace resources. The current ApplicationSet does not yet configure managed namespace metadata.

Platform components do not use this chart. Applications that demonstrably need multiple independently deployed images may become multiple application registrations or justify one narrow chart extension; do not add a speculative component framework.

## Actual project repositories and images

Actual project repositories replace legacy split configuration repositories. They own application code and a Dockerfile. Kubernetes manifests are not required for applications that fit the generic chart.

A Dockerfile alone is not deployable: an image must be built and published. The minimal initial project contract is expected to be:

```text
Dockerfile
.github/workflows/image.yaml
```

The workflow should call a centrally maintained reusable workflow and publish immutable commit-SHA images. A literal Dockerfile-only repository requires organization-level build automation and is deferred until that is proven worthwhile.

Planned sample repository: `SystemConsultantGroup/kubernetes-hello-world`. It has not yet been created.

## ApplicationSet model

ApplicationSets read `applications/*/meta.yaml` with a Git files generator.

Expected generated applications:

- Production for each registration
- Staging for each registration
- One preview per eligible open pull request

The project repository is used for repository identity, PR discovery, and image revision. The generated Argo CD Application deploys the central `argocd/charts/application` chart rather than application-owned Kubernetes manifests.

PR preview behavior:

1. A maintainer applies a `preview` label to a pull request in the registered project repository.
2. The Pull Request generator creates an Application pinned to the PR head SHA.
3. CI must have published the matching immutable image.
4. Argo deploys it to `<application>-preview-<number>` at `preview-<number>.<domain>`.
5. New commits update the generated Application.
6. Closing the PR or removing the label deletes the Application and prunes its resources.

A GitHub App with read-only organization repository/PR access is preferred over a personal token. Polling can start at five minutes; add the ApplicationSet webhook only if the delay matters.

## Per-application routing and TLS

Use one shared Cilium Gateway and a per-application Gateway API ListenerSet. Ownership is split deliberately:

- The platform owns the shared Gateway, its `allowedListeners` policy, Gateway API CRDs, and cert-manager configuration.
- Trusted central metadata and the generic chart define the ListenerSet shape and domain allocation.
- The production Argo release is the single resource owner that applies the namespaced ListenerSet; staging and previews must never apply it.
- cert-manager creates the resulting Certificate and TLS Secret in the ListenerSet namespace.

The ListenerSet has two HTTPS listeners:

- `<domain>`
- `*.<domain>`

Both reference the same TLS Secret, so cert-manager creates one Certificate containing the apex and wildcard SANs. Production attaches to the apex listener; staging and previews attach to the wildcard listener. During hello-world migration, its current static Gateway listener and explicit Certificate must be removed only after the ListenerSet is accepted and serving the replacement certificate.

ExternalDNS should create explicit records from HTTPRoute hostnames:

- `<domain>`
- `staging.<domain>`
- `preview-<number>.<domain>`

Do not create wildcard DNS records merely because the certificate contains a wildcard SAN.

Current platform implications:

- The repository declares Gateway API `v1.6.1`, but `scripts/commands/install/gateway-api.sh` does not yet install the ListenerSet CRD.
- The shared Gateway must enable `spec.allowedListeners` for selected application namespaces.
- Cilium `1.20.0` declares ListenerSet support.
- cert-manager `1.21.0` supports ListenerSets but needs `config.gatewayAPI.enableListenerSet: true` and the `ListenerSets` feature gate.
- ExternalDNS chart `1.21.1` runs ExternalDNS `0.21.0`, which supports HTTPRoutes attached through ListenerSets.
- Current ExternalDNS configuration is restricted to `scg.sh`; other DNS zones need explicit provider and domain-filter configuration.

## Custom routes

The generated route covers the normal one-hostname, one-Service case. An application needing custom path routing or multiple HTTPRoutes sets:

```yaml
route: custom
```

and adds:

```text
applications/<application>/routes/
  kustomization.yaml
  *.yaml
```

The ApplicationSet adds this directory as an additional Kustomize source and injects the environment-specific hostname and ListenerSet parent. Custom routing is an explicit deviation, so only affected applications pay the extra files.

The custom directory is intended for Gateway API route kinds, not arbitrary Gateways, ListenerSets, Certificates, Deployments, or cluster-scoped resources. ListenerSet shape and domain allocation remain controlled by trusted central templates, while the production release is their sole Argo resource owner. The exact kind allowlist and environment-patching mechanism must be validated during implementation.

## Security boundaries

Do not deploy pull-request content through the current broad `scg` AppProject. The existing ApplicationSet still uses `project: scg`; replacing that assignment is a required migration step, not current behavior.

Create restrictive application projects, especially for previews:

- Hard-code the AppProject in generated Applications.
- Restrict source repositories to registered project repositories plus this central chart repository.
- Restrict destination namespace patterns.
- Deny cluster-scoped resources for previews.
- Deny Gateway, ListenerSet, Certificate, RBAC, and other infrastructure ownership from preview sources.
- Apply restricted Pod Security Admission labels to generated namespaces.
- Keep domain, Gateway listener, certificate, and project selection controlled by trusted central metadata/templates rather than pull-request content.
- Allow only maintainers to apply the `preview` label.

The precise Argo CD and Kubernetes enforcement needed to prevent a manifest from escaping its generated namespace remains an implementation validation item.

## Deliberate non-goals for the first version

- Universal arbitrary Kubernetes escape hatches
- Multi-component application framework
- Databases or Redis managed by the application chart
- Persistent volumes
- Autoscaling
- Per-application service accounts/RBAC
- Arbitrary pod scheduling controls
- Long-lived environment branches
- Wildcard DNS records
- Migrating legacy `*-config` repositories as-is

## Open decisions

1. **Promotion semantics:** deploying the same `main` revision to staging and production simultaneously makes staging ineffective. Decide how a verified staging image is promoted to production.
2. **Image publication:** choose GHCR visibility/authentication and define the reusable build workflow.
3. **Stable image revision:** define how production and staging select immutable project-repository commit SHAs or digests.
4. **Secrets:** define how per-environment Secrets are provisioned before relying on `envFromSecrets`.
5. **Custom-route injection:** prove the multi-source Kustomize hostname/parent patching model.
6. **Namespace enforcement:** verify that preview Applications cannot deploy resources outside their generated namespace.
7. **Multi-component applications:** use the legacy audit to determine whether splitting registrations is enough.
8. **Sample:** create `SystemConsultantGroup/kubernetes-hello-world` only after the image and chart contracts are executable end to end.

## Planned evidence

`LEGACY_CONFIG_SWEEP.md` is a temporary orchestration handoff for a read-only audit of legacy `*-config` repositories. Its resulting `legacy-config-sweep-report.md` should test this proposal against real applications and identify only evidence-backed deviations. The handoff deletes itself; this design document must remain.

## References

- Argo CD Pull Request generator: <https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Pull-Request/>
- Argo CD Matrix generator: <https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Matrix/>
- Gateway API ListenerSet: <https://gateway-api.sigs.k8s.io/guides/user-guides/listener-set/>
- cert-manager Gateway and ListenerSet support: <https://cert-manager.io/docs/usage/gateway/>
- ExternalDNS Gateway API source: <https://kubernetes-sigs.github.io/external-dns/latest/docs/sources/gateway-api/>
