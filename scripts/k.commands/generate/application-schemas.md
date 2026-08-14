# application-schemas

Vendors application schema types at the Kubernetes and Gateway API versions pinned in `state.yaml`.

## Description

Downloads the pinned Kubernetes OpenAPI document and standard Gateway API HTTPRoute CRD, then extracts only the Kubernetes types used by application metadata and the complete `HTTPRouteRule` schema. It removes descriptions, makes structured objects strict, normalizes `IntOrString`, and generates the application chart's merged values schema.

Generated files:

```text
working/types/kubernetes.schema.json
working/types/httprouterule.schema.json
argocd/charts/application/values.schema.json
```

## Usage

```text
k generate application-schemas
k generate application-schemas --check
```

`--check` exits unsuccessfully when committed output is stale without modifying files.

## Requirements

- `state.yaml` contains `kubernetes.version` and `gateway-api.version`.
- `curl`, `jq`, and `yq` are available.
- Network access to `raw.githubusercontent.com` is available.
