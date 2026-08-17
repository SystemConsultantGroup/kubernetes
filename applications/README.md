# Applications

This directory contains workloads deployed by the SCG platform.
Application owners normally change these files and submit pull requests.
Merging to `main` makes the declared state available to Argo CD.

Each application uses exactly one layout:

- managed: `meta.yaml` plus instance lock files under `instances/`;
- custom: a root `kustomization.yaml` rendered directly by Argo CD.

Do not mix the layouts.
Do not put credentials in application files.

## Managed application

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

`meta.yaml` contains workload names and runtime configuration.
Stable instance files contain the immutable source and image locks.
Production is required; testing is optional.
Preview identity comes from the preview file path.

### Minimal example

The repository's minimal public HTTP example is
[`hello-world/`](hello-world/).

`applications/hello-world/meta.yaml`:

```yaml
fe:
  http:
    port: 8080
    domain: hello.world.scg.sh
```

The production, testing, and preview lock files all use the same immutable
source and image pair in this example.
The generated identities are:

```text
hello-world-production
hello-world-testing
hello-world-preview-fe-1
```

Each instance creates a Deployment and Service named `hello-world-fe`.
The Service listens on port 80 and targets container port 8080.
Production routing uses `hello.world.scg.sh`; testing and preview use the
platform-generated hostnames.
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

Preview deployments use one replica.
A preview renders only the selected workload; references to other local
workloads target their testing Services.

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

Use `kustomization.yaml`, not `kustomize.yaml`.
Do not add `meta.yaml` to a custom application.

## Validation and detailed schema

The shared chart validates workload configuration with a generated strict JSON
schema.
It accepts only the fields documented in
[`../argocd/charts/application/README.md`](../argocd/charts/application/README.md),
including Kubernetes-native resources, environment sources, readiness probes,
and Gateway API HTTP route rules.

The ApplicationSets that turn these files into Argo CD Applications are
explained in [`../argocd/application-sets/README.md`](../argocd/application-sets/README.md).
