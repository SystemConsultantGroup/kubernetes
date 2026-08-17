# Application chart

This chart renders one managed SCG application instance. Argo CD supplies
values from the application's `meta.yaml`, its instance lock, and an internal
`_context` object.

## Inputs

The context contains:

- `_context.application`, the application name;
- `_context.instance.type`, one of `production`, `testing`, or `preview`;
- preview context also contains `workload` and `pullRequest`.

Each workload value combines runtime metadata with an immutable `source` and
`image` lock. The generated values schema rejects unknown fields and validates
Kubernetes and Gateway API structures.

## Outputs

For each rendered workload the chart creates a Deployment. A workload with
`http` also receives a ClusterIP Service on port 80. Public domains produce
Gateway API resources according to the instance type:

- production uses the declared hostname;
- testing uses the application's testing hostname;
- preview uses the preview hostname and renders only the selected workload,
  routing other declared backends to testing when needed.

The chart applies the platform's baseline pod security settings, labels, image
policy, and source metadata. Application metadata controls only the fields
exposed by the application schema.

## Local rendering

Render the example production instance from the repository root with:

```bash
helm template app-production-hello-world argocd/charts/application \
  --values applications/hello-world/meta.yaml \
  --values applications/hello-world/instances/production.yaml \
  --set _context.application=hello-world \
  --set _context.instance.type=production
```

Inspect the output for correct namespaces, routes, services, and image locks.
Do not apply it to a cluster for local validation.

## Generated schema

`values.schema.json` is generated from
[`values.schema.source.json`](values.schema.source.json), the pinned Kubernetes
and Gateway API definitions, and the chart's effective values schema. Do not
edit `values.schema.json` directly. Regenerate it with:

```bash
k generate application-schemas
k generate application-schemas --check
```

The chart's templates and generated schema are shared platform code; changes
require operator review even when they are motivated by one application.
