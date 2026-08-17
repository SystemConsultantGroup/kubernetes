# Applications

This directory contains workloads deployed by the SCG platform. Application
owners normally change these files and submit a pull request; merging to
`main` makes the declared state available to Argo CD.

## Choose one layout

Each application directory uses exactly one layout.

### Managed application

A managed application uses the shared Helm chart:

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

`meta.yaml` defines workload names and runtime settings such as replicas,
resources, environment variables, readiness probes, and HTTP routing. The
production instance is required; testing is optional. Stable instance files
contain the immutable source and image lock for each workload. A preview file
contains one lock, while its workload and pull request number come from its
path.

### Custom Kustomize application

A custom application has a standard Kustomize entrypoint at its root:

```text
applications/example/
  kustomization.yaml
  resources.yaml
```

Argo CD renders the directory directly. Do not add `meta.yaml` to this layout,
and use `kustomization.yaml`, not `kustomize.yaml`.

## Configure a managed workload

A workload without `http` produces a Deployment only. `http.port` adds a
ClusterIP Service on port 80 targeting the container port. `http.domain` also
adds public Gateway API routing.

A domain can be a hostname, several hostnames, or an externally managed
hostname:

```yaml
web:
  http:
    port: 8080
    domain: example.scg.sh
```

```yaml
web:
  http:
    port: 8080
    domain:
      - example.scg.sh
      - www.example.scg.sh
```

```yaml
web:
  http:
    port: 8080
    domain:
      name: example.example.org
      external: true
```

For production, an external domain uses an HTTP listener and does not create
a certificate or an ExternalDNS record. Use it only when TLS termination and
DNS are managed outside this platform. Testing and preview traffic uses the
platform's wildcard listeners.

`rules` are optional. Without them, the chart creates a catch-all route to the
owning workload. Rules require `domain` and use the Gateway API `HTTPRouteRule`
shape.

## Immutable instance locks

Every stable workload lock must contain:

- an HTTPS Git repository URL ending in `.git`, without credentials;
- a full lowercase 40-character commit SHA; and
- a fully qualified lowercase OCI image reference pinned by a SHA-256 digest.

The source revision and image digest should come from the same build. Do not
use mutable image tags in an instance file.

## Pull request previews

Place a preview lock at:

```text
applications/example/instances/preview/web/123.yaml
```

The file contains only the selected workload's `source` and `image` fields:

```yaml
source:
  repository: https://github.com/example/project.git
  revision: 0123456789abcdef0123456789abcdef01234567
image: registry.example.org/project/web@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

The path determines the workload and pull request number. Argo CD creates a
separate preview Application and namespace, with a hostname of the form
`<application>-<workload>-<pull-request>.preview.scg.sh`. Removing the file
removes the generated preview resources.

## References

- [`hello-world/`](hello-world/) is a complete managed application example.
- [`../argocd/charts/application/`](../argocd/charts/application/) contains
  the renderer and effective values schema.
- [`../argocd/application-sets/`](../argocd/application-sets/) explains how
  application files become Argo CD Applications.
