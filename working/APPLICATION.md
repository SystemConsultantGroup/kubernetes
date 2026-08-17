# SCG application registry

Status: design draft. These schemas replace the previous contents of `working/` and are not yet operationally authoritative.

## Purpose

The configuration repository records only runtime intent and immutable instance state. It does not register source repositories, branches, or workflow ownership in application metadata.

Application repository workflows decide which configuration path to propose changing. Acceptance and authorization remain responsibilities of the configuration repository's review and CI policy.

## Files

| File | Purpose |
| --- | --- |
| `meta.schema.json` | Application workload and HTTP configuration |
| `lock.schema.json` | One workload's immutable source/image pair; validates preview files directly |
| `stable-instance.schema.json` | Production or testing locks for every workload |
| `types/kubernetes.schema.json` | Vendored Kubernetes types used by workload metadata |
| `types/httprouterule.schema.json` | Vendored complete standard `HTTPRouteRule` |
| `../argocd/charts/application/values.schema.json` | Generated schema for effective merged Helm values |

The vendored type schemas have descriptions removed and object fields made strict. Kubernetes OpenAPI v2's `int-or-string` marker is expanded to its real integer-or-string wire shape; remaining field schemas and Kubernetes validation extensions come from the pinned upstream definitions.

The standard Gateway API CRD channel is used. Features accepted by the API but unsupported by Cilium must still be detected by conformance tests or policy validation.

## Registry layout

```text
applications/
  <application>/
    meta.yaml
    instances/
      production.yaml
      testing.yaml                     # optional
      preview/
        <workload>/
          <pull-request-number>.yaml
```

Application and workload names are lowercase Kubernetes DNS labels. Existing names such as `fe` and `be` are preserved as first-class workload names.

## Application directory modes

Each `applications/<application>/` directory uses exactly one of two mutually exclusive modes.

### Chart-managed application

A conventional application contains `meta.yaml` and `instances/`:

```text
applications/example/
  meta.yaml
  instances/
    production.yaml
    testing.yaml
    preview/
      fe/
        42.yaml
```

Its instance files are discovered by an ApplicationSet, and every generated Argo CD Application renders the central Helm chart. Metadata and instance schemas, platform defaults, testing, and single-workload previews apply to this mode.

### Kustomize-managed application

An exceptional application contains a standard `kustomization.yaml` entrypoint:

```text
applications/example/
  kustomization.yaml
  resources.yaml
```

A separate ApplicationSet scans the exact one-level pattern `applications/*/kustomization.yaml` and points Argo CD directly at the containing directory. Nested Kustomizations are not independently discovered. The central metadata and instance schemas do not apply, and the directory owns its manifest, image, and environment conventions.

Kustomize-managed applications initially represent one directly rendered Application. Testing and production overlay conventions will be added only when a real application demonstrates the requirement.

CI must reject an application directory that contains both `meta.yaml` and `kustomization.yaml`, contains neither entrypoint, or uses the nonstandard filename `kustomize.yaml`. Kustomize mode is an escape hatch and remains constrained by its AppProject, admission policy, review policy, and namespace permissions.

## Application metadata

`meta.yaml` is a map from workload name to workload configuration. There is no `workloads:` wrapper and no duplicated `name` field.

```yaml
fe:
  replicas: 2
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      memory: 512Mi
  env:
    - name: LOG_LEVEL
      value: info
  envFrom:
    - secretRef:
        name: application-config
  readinessProbe:
    httpGet:
      path: /health/ready
      port: 3000
  http:
    port: 3000
    domain:
      - example.scg.sh
      - name: example.cs.skku.edu
        external: true
    rules:
      - name: root
        matches:
          - path:
              type: PathPrefix
              value: /

      - name: api
        matches:
          - path:
              type: PathPrefix
              value: /api
        backendRefs:
          - name: be
            port: 80

be:
  http:
    port: 8000
```

A workload may configure:

- `replicas`;
- native Kubernetes `ResourceRequirements`;
- native Kubernetes `EnvVar` and `EnvFromSource` lists;
- a native Kubernetes `Probe` for readiness;
- an optional HTTP Service and public exposure.

The chart owns names, labels, selectors, images, image pull policy, service accounts, security contexts, namespaces, and other Pod and Deployment policy.

### HTTP behavior

A workload without `http` is a long-running worker and receives no Service.

```yaml
worker: {}
```

A workload with only `http.port` receives a ClusterIP Service but no public route.

```yaml
be:
  http:
    port: 8000
```

The Service always exposes port 80 and targets `http.port`:

```text
Service be:80 -> container port 8000
```

A `domain` enables public routing. A string is a platform-managed domain:

```yaml
domain: example.scg.sh
```

An object states DNS ownership explicitly:

```yaml
domain:
  name: example.cs.skku.edu
  external: true
```

`external: true` means the platform does not own the DNS record. The precise TLS and firewall behavior for external domains remains platform policy and must be documented before deployment.

A domain list applies the same rule set to every listed domain. A domain without `rules` receives one derived catch-all rule targeting the owning workload. `rules` cannot be supplied without `domain`.

### HTTPRouteRule reuse

Every `http.rules[]` item uses the complete pinned Gateway API `HTTPRouteRule` schema. This includes:

- `name`;
- `matches`;
- `filters`;
- `backendRefs`;
- `timeouts`.

All nested standard Gateway API match, filter, timeout, and backend-reference fields are accepted by the vendored schema.

The chart supplies defaults only when fields are absent:

- absent `name` becomes a deterministic name based on workload and rule position;
- absent `backendRefs` targets the workload owning the HTTP block on Service port 80;
- a redirect-only rule remains backendless;
- explicit fields always win.

For declared workload Service references with no explicit namespace, the renderer chooses the instance namespace. Explicit namespaces and non-Service references are preserved and remain subject to Gateway API `ReferenceGrant`, admission, and controller policy.

Because AppProjects cannot constrain nested HTTPRoute fields, arbitrary extension references, mirrors, and cross-namespace references require separate admission and `ReferenceGrant` controls.

## Immutable workload lock

A lock connects one exact source commit to one exact OCI image:

```yaml
source:
  repository: https://github.com/SystemConsultantGroup/example.git
  revision: "0123456789abcdef0123456789abcdef01234567"
image: ghcr.io/systemconsultantgroup/example@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
```

The repository is a credential-free HTTPS clone URL ending in `.git`. The revision is a full lowercase 40-character Git commit SHA.

The image is a fully qualified lowercase OCI reference pinned by a SHA-256 digest. Tags and tag-plus-digest references are forbidden. Kubernetes can use the value directly as `container.image`.

CI must verify that image provenance binds the digest to the declared repository and revision. The Helm chart can derive a provider-specific commit URL and add it as an Argo CD external link on each rendered Deployment.

## Stable instances

Production and testing files map every metadata workload to its lock:

```yaml
fe:
  source:
    repository: https://github.com/SystemConsultantGroup/frontend.git
    revision: "1111111111111111111111111111111111111111"
  image: ghcr.io/systemconsultantgroup/frontend@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

be:
  source:
    repository: https://github.com/SystemConsultantGroup/backend.git
    revision: "2222222222222222222222222222222222222222"
  image: ghcr.io/systemconsultantgroup/backend@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
```

`production.yaml` is required. `testing.yaml` is optional. Cross-file validation requires each stable instance's workload keys to equal the keys in `meta.yaml` exactly.

## Preview instances

A preview is inherently single-workload. Application, workload, and pull-request identity come from its path:

```text
applications/example/instances/preview/fe/42.yaml
```

The file therefore contains only one lock and is validated directly by `lock.schema.json`:

```yaml
source:
  repository: https://github.com/SystemConsultantGroup/frontend.git
  revision: "3333333333333333333333333333333333333333"
image: ghcr.io/systemconsultantgroup/frontend@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
```

A preview Application deploys only that workload. For every HTTP rule relevant to the preview hostname:

- a backend targeting the previewed workload resolves to the preview namespace;
- a backend targeting another declared workload resolves to the testing namespace;
- a fully explicit external backend remains explicit.

For example, an `fe` preview routes `/` to preview `fe` and `/api` to testing `be`. A `be` preview routes `/` to testing `fe` and `/api` to preview `be`.

Cross-namespace testing backends require narrowly scoped Gateway API `ReferenceGrant` resources. A preview depending on sibling workloads requires a valid testing instance for those workloads.

Deleting the preview file removes its generated Argo CD Application and namespace.

## ApplicationSet and Helm flow

```text
meta.yaml + one instance file
            |
            v
ApplicationSet Git file generator
            |
            v
one Argo CD Application per instance file
            |
            v
central Helm application chart
            |
            v
Deployment, optional Service, and optional HTTPRoute resources
```

The ApplicationSets use these discovery patterns:

```text
applications/*/instances/production.yaml
applications/*/instances/testing.yaml
applications/*/instances/preview/*/*.yaml
```

No generated global instance index is required. Production and testing files produce one Application each; every preview file produces one Application.

The source schemas describe independent repository files. The chart's generated `values.schema.json` validates their effective merged values. The preview ApplicationSet carries path-derived identity and the single preview lock into those values without duplicating identity in the preview file.

## Validation beyond JSON Schema

JSON Schema validates individual files. CI must additionally reject:

- duplicate YAML mapping keys before schema validation;
- stable instance workload sets that differ from metadata;
- preview workload paths that do not exist in metadata;
- missing production instances;
- duplicate domains across the complete registry;
- backend references to declared workloads that lack `http`;
- conflicting rules after multiple production domains collapse onto one testing or preview hostname;
- preview routes requiring a missing testing backend;
- source/image pairs whose provenance does not match;
- unsupported Gateway API features for the deployed Cilium version;
- overlong derived Application, namespace, Service, and hostname values;
- unauthorized workflow changes to configuration paths.

Application repository workflow configuration is not authorization by itself. Fully automated merges require trusted changed-path authorization outside application metadata; reviewed pull requests can instead rely on branch protection and CODEOWNERS.

## Upstream schema sources

`state.yaml` is the sole authority for Kubernetes and Gateway API versions. Run:

```text
k generate application-schemas
```

The generator downloads the corresponding pinned sources:

```text
https://raw.githubusercontent.com/kubernetes/kubernetes/v<version>/api/openapi-spec/swagger.json
https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v<version>/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
```

It recursively extracts the Kubernetes types referenced by metadata, extracts the complete standard Gateway API `HTTPRouteRule`, removes documentation-only data, makes object fields strict, normalizes OpenAPI constructs such as `IntOrString`, and generates the chart's self-contained effective values schema.

Generated files have stable, version-independent paths:

```text
working/types/kubernetes.schema.json
working/types/httprouterule.schema.json
argocd/charts/application/values.schema.json
```

Local references keep validation reproducible and offline after generation. CI must run `k generate application-schemas --check` and reject stale output whenever `state.yaml` or the schema source changes. Final rendered manifests must additionally be validated against the actual cluster APIs.
