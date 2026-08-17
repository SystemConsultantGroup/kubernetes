# Application chart

This chart renders one managed SCG application instance. ApplicationSets supply
`meta.yaml`, an immutable instance lock, and an internal `_context` value.

## Inputs

The context contains:

- `application`, the application name;
- `instance.type`, one of `production`, `testing`, or `preview`; and
- for previews, `instance.workload` and `instance.pullRequest`.

Each workload combines runtime metadata with a required `source` and `image`
lock. The generated schema rejects unknown fields and validates the selected
Kubernetes and Gateway API structures.

## Outputs

Each rendered workload produces a Deployment. A workload with `http` also gets
a ClusterIP Service on port 80. Public routing depends on the instance:

- production uses each declared domain and creates certificates unless the
  domain is marked external;
- testing uses `<application>.testing.scg.sh`; and
- preview uses
  `<application>-<workload>-<pull-request>.preview.scg.sh` and renders only the
  selected workload.

Preview routes that reference another local workload target that workload's
testing Service. The chart also applies baseline pod security, labels, image pull policy, and
source metadata. Application metadata controls only schema-exposed fields.

## Local rendering

From the repository root, render the example production instance:

```bash
helm template app-production-hello-world argocd/charts/application \
  --values applications/hello-world/meta.yaml \
  --values applications/hello-world/instances/production.yaml \
  --set _context.application=hello-world \
  --set _context.instance.type=production
```

Inspect namespaces, routes, Services, and image locks. Do not apply the output
to a cluster for local validation.

## Generated schema

[`values.schema.json`](values.schema.json) is generated from
[`values.schema.source.json`](values.schema.source.json) and version-pinned
Kubernetes and Gateway API definitions. Edit the source file, not the generated
file:

```bash
k generate application-schemas
k generate application-schemas --check
```

Templates and the generated schema are shared platform code and require
operator review.
