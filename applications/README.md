# Applications

This directory contains the workloads deployed by the SCG platform. Application
owners normally make changes here and submit them through a pull request.
Merging to `main` makes the declared application state available to Argo CD.

## Choose an application layout

Each application directory uses exactly one of these layouts.

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

`meta.yaml` maps workload names to runtime configuration. A workload can
specify replicas, resources, environment variables, environment sources, a
readiness probe, and optional HTTP configuration.

Stable instance files map the same workload names to immutable source and image
locks. `production.yaml` is required; `testing.yaml` is optional. A preview
file contains one lock, and its workload and pull request number come from its
path.

### Custom Kustomize application

A custom application has a standard `kustomization.yaml` at the application
root:

```text
applications/example/
  kustomization.yaml
  resources.yaml
```

The directory is rendered directly by Argo CD. It must not also contain
`meta.yaml`, and the entrypoint must be named `kustomization.yaml`, not
`kustomize.yaml`.

## Managed application configuration

A workload without `http` is treated as a worker and receives no Service. A
workload with `http.port` receives a ClusterIP Service whose port 80 targets
that container port. Adding `http.domain` also creates public routing through
the platform Gateway.

Use a string for a platform-managed hostname:

```yaml
web:
  http:
    port: 8080
    domain: example.scg.sh
```

Use an object when DNS is managed elsewhere:

```yaml
web:
  http:
    port: 8080
    domain:
      name: example.example.org
      external: true
```

Rules are optional. When omitted, the chart creates a catch-all route to the
owning workload. Rules require a domain and use the standard Gateway API
`HTTPRouteRule` shape.

## Immutable instance locks

Each stable workload lock must contain:

- a credential-free HTTPS Git repository URL ending in `.git`;
- a full lowercase 40-character commit SHA;
- a fully qualified lowercase OCI image reference pinned by a SHA-256 digest.

The source commit and image digest are expected to describe the same build.
Do not use mutable image tags in an instance file.

## Pull request previews

A preview file is placed at:

```text
applications/example/instances/preview/web/123.yaml
```

It contains only the `source` and `image` lock for `web`. Argo CD creates a
separate preview application and namespace from that path. Removing the file
removes the generated preview application and namespace.

## References

- [`hello-world/`](hello-world/) is a complete managed application example.
- [`../argocd/charts/application/`](../argocd/charts/application/) contains the
  shared renderer and its effective values schema.
- [`../argocd/application-sets/`](../argocd/application-sets/) documents how
  application files become Argo CD Applications.
