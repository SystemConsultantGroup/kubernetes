[한국어](README.md) | English

# Applications

This directory contains workloads deployed by the SCG platform.
Application owners normally change these files and submit pull requests.
Merging to `main` makes the declared state available to Argo CD.

Choose one layout for the application directory:

| Layout | Use it when | Entrypoint |
| --- | --- | --- |
| Managed | The shared Deployment, Service, routing, and secret conventions fit | `meta.yaml` and `instances/` |
| Custom | The application needs Kubernetes resources the shared chart does not expose | `kustomization.yaml` |

Do not mix the layouts or put credentials in application files. Start with the
managed layout unless it cannot express the workload; it provides stricter
validation and consistent previews.

## Managed application

The normal workflow is:

1. define runtime behavior once in `meta.yaml`;
1. add an immutable production lock for every workload;
1. optionally add testing or pull-request preview locks; and
1. submit the changes together so metadata and locks remain consistent.

A managed application has this shape:

```text
applications/example/
  meta.yaml
  instances/
    production.yaml
    testing.yaml
    preview/
      web/
        123.yaml
```

`meta.yaml` contains workload names and runtime configuration, but never
`source` or `image`. Stable instance files contain exactly those immutable
source and image locks. Production is required; testing is optional. Preview
identity comes from the preview file path.

Application, workload, and generated identity components use lowercase DNS-style
names. Each complete Argo CD identity must fit 63 characters, including
`-production`, `-testing`, or `-preview-<workload>-<pull-request>`. Internal
workload resources can use stable hash suffixes when needed, but Application and
namespace identities cannot.

After bootstrap, application repositories can maintain these locks through the
shared [application delivery workflows](../.github/workflows/README.en.md). The workflow publishes an
immutable image for `main`, `testing`, or a same-repository pull request and then
applies the corresponding production, testing, or preview lock here. Closing a
pull request removes its preview lock.

### Minimal example

The repository's minimal public HTTP example is
[`example/`](example/README.en.md).

`applications/example/meta.yaml`:

```yaml
fe:
  http:
    port: 8080
    domain: example.scg.sh
```

The production, testing, and preview lock files all use the same immutable
source and image pair in this example.
The generated identities are:

```text
example-production
example-testing
example-preview-fe-1
```

Each instance creates a Deployment and Service named `example-fe`.
The Service listens on port 80 and targets container port 8080.
Production routing uses `example.scg.sh`; testing and preview use the
platform-generated hostnames and accept internet clients only from
`115.145.150.0/24`.
See the chart README for the complete naming and routing rules.

### Full example

`meta.yaml` can configure multiple workloads and route between them:

```yaml
web:
  replicas: 2
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  env:
    - name: LOG_LEVEL
      value: info
    - name: PORT
      value: "8080"
  envFrom:
    - configMapRef:
        name: shop-config
  readinessProbe:
    httpGet:
      path: /ready
      port: http
    periodSeconds: 10
  http:
    port: 8080
    domain:
      name: shop.example.org
      external: false
    rules:
      - name: api
        matches:
          - path:
              type: PathPrefix
              value: /api
        backendRefs:
          - name: api
            port: 80
      - name: web
        backendRefs:
          - name: web
            port: 80

api:
  replicas: 2
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
  envFrom:
    - secretRef:
        name: shop-api-secrets
  readinessProbe:
    httpGet:
      path: /healthz
      port: http
  http:
    port: 9000
```

The `api` workload has a Service but no public route because it has no domain.
The `web` rules route `/api` to the `api` Service and all other traffic to the
`web` Service.
Backend references use workload keys; the chart expands local workload
references to their generated Service names.

The corresponding production instance must lock both workloads:

```yaml
web:
  source:
    repository: https://github.com/example/shop-web.git
    revision: 0123456789abcdef0123456789abcdef01234567
  image: registry.example.org/example/shop-web@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

api:
  source:
    repository: https://github.com/example/shop-api.git
    revision: fedcba9876543210fedcba9876543210fedcba98
  image: registry.example.org/example/shop-api@sha256:fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210
```

Each source revision must be a full lowercase 40-character Git SHA.
Each image must be a lowercase fully qualified OCI reference pinned by a
64-character lowercase SHA-256 digest.
The source and image should come from the same build.

### Preview instances

Place a preview lock at:

```text
applications/example/instances/preview/web/123.yaml
```

The file contains only the selected workload's lock:

```yaml
source:
  repository: https://github.com/example/shop-web.git
  revision: 0123456789abcdef0123456789abcdef01234567
image: registry.example.org/example/shop-web@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

The generated preview identity is:

```text
<application>-preview-<workload>-<pull-request>
```

Preview deployments use one replica. A preview renders only the selected
workload; references to other local workloads target their testing Services.

### Managed secret values

Managed workloads automatically receive environment values from the platform's
Vault integration when a corresponding path exists. Application metadata never
contains Vault configuration or plaintext values. Production and testing use
their own paths; previews inherit testing values and then apply a shared preview
override for the selected workload.

Applications must validate required values at startup because a missing Vault
path is allowed. Testing credentials must be safe for preview code. Members
responsible for secret values should follow the
[Vault application-value workflow](../argocd/platform/vault/README.en.md#managing-application-values).

## Custom Kustomize application

A custom application has a standard Kustomize entrypoint at its root:

```text
applications/example/
  kustomization.yaml
  resources.yaml
```

The generated Argo CD Application and namespace are named:

```text
<application>
```

Use `kustomization.yaml`, not `kustomize.yaml`. Do not add `meta.yaml` or an
`instances/` tree. Custom applications do not receive managed testing or preview
instances; define every desired resource in the Kustomization.

Resources with an explicit namespace may target only the application's generated
namespace, and a declared Namespace must use the application name. Platform
review of merged Git changes is the authorization boundary; application
developers receive no cluster or `k` credentials.

## Validation and detailed schema

Platform engineers run repository checks during review to validate the managed
or custom layout, required production lock, workload consistency, preview
identity, generated name limits, and local renders. Application developers do
not need access to the platform-only `k` command.

Before requesting review, confirm that:

- the application directory uses only one layout;
- every stable lock contains exactly the workloads in `meta.yaml`;
- every lock uses a full commit SHA and digest-pinned image from the same build;
- preview workload and pull-request identities match the file path;
- domains, routes, and referenced Services are intentional; and
- no plaintext credential or local configuration file is included.

The shared chart validates effective workload configuration with a generated
strict JSON schema.
It accepts only the fields documented in
[`../argocd/charts/application/README.en.md`](../argocd/charts/application/README.en.md),
including Kubernetes-native resources, environment sources, readiness probes,
and Gateway API HTTP route rules.

The ApplicationSets that turn these files into Argo CD Applications are
explained in
[`../argocd/application-sets/README.en.md`](../argocd/application-sets/README.en.md).
