# application-schemas

Generates or checks the managed application chart schema from the API versions
pinned in `state.yaml`.

## Behavior

The command downloads the pinned Kubernetes OpenAPI document and Gateway API
`HTTPRoute` CRD, selects the types used by application metadata, and merges
those definitions with the chart's source schema. It removes descriptions,
makes structured objects strict, normalizes Kubernetes `IntOrString`, and writes:

```text
argocd/charts/application/values.schema.json
```

`--check` compares the generated result with the committed file and exits with
an error when it is stale. It does not modify files.

## Usage

```bash
k generate application-schemas
k generate application-schemas --check
```

## Prerequisites

- `state.yaml` contains `kubernetes.version` and `gateway-api.version`.
- `curl`, `jq`, and `yq` are available.
- Network access to the pinned definitions on `raw.githubusercontent.com` is
  available.

Edit `values.schema.source.json`, never the generated schema, then run the
command without `--check` and review the diff.
