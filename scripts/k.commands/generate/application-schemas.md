# application-schemas

Generates the application chart schema from the Kubernetes and Gateway API versions pinned in `state.yaml`.

## Description

Downloads the pinned Kubernetes OpenAPI document and standard Gateway API HTTPRoute CRD, then extracts only the Kubernetes types used by application metadata and the complete `HTTPRouteRule` schema. It removes descriptions, makes structured objects strict, normalizes `IntOrString`, and generates the application chart's merged values schema.

Generated file:

```text
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
