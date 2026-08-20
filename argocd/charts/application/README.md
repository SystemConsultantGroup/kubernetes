# Application chart

This chart renders one managed SCG application instance.
ApplicationSets combine three inputs:

1. application metadata from `applications/<application>/meta.yaml`;
1. an immutable source and image lock from an instance file; and
1. an internal `_context` describing the application and instance type.

The chart is platform code.
Changes can affect every managed application.

## Values assembly

A stable production or testing render is conceptually:

```yaml
_context:
  application: shop
  instance:
    type: production

web:
  replicas: 2
  http:
    port: 8080
  source:
    repository: https://github.com/example/shop-web.git
    revision: 0123456789abcdef0123456789abcdef01234567
  image: registry.example.org/example/shop-web@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

The metadata and instance files are merged by Helm before schema validation.
Application owners normally keep runtime configuration in `meta.yaml` and locks
in `instances/`.

`source` and `image` are technically part of the final workload schema, but
should not normally be placed in `meta.yaml`.

## Naming model

ApplicationSet identities use the application name first:

| Instance | Application, release, and namespace |
| --- | --- |
| production | `<application>-production` |
| testing | `<application>-testing` |
| preview | `<application>-preview-<workload>-<pull-request>` |
| custom Kustomize | `<application>` |

Inside a managed namespace, workload resources use:

```text
<application>-<workload>
```

For example, `shop` with a `web` workload creates:

```text
Deployment: shop-web
Service:    shop-web
Secret:     shop-web-environment
```

The Secret only exists when centrally managed Vault integration is enabled and
the corresponding Vault path contains data.

When a chart-controlled name would exceed its Kubernetes or DNS label limit,
the chart preserves a readable prefix and appends a stable hash of the complete
name. ApplicationSet names and namespaces do not add a separate `app-` prefix;
repository checks enforce their combined length before reconciliation.

## Schema rules

The generated `values.schema.json` is strict:

- unknown top-level keys are rejected;
- unknown workload fields are rejected;
- nested Kubernetes and Gateway API objects reject unknown fields;
- workload names must be lowercase DNS-compatible names; and
- the chart requires at least one workload and a source/image lock for every
  workload that it renders.

The JSON schema is generated from
[`values.schema.source.json`](values.schema.source.json), Kubernetes
definitions, and Gateway API definitions.
The pinned source versions are in `state.yaml`.

## Workload names

Each top-level workload key must be 1 to 63 characters and match:

```text
^[a-z0-9](?:[-a-z0-9]*[a-z0-9])?$
```

Names may contain lowercase letters, digits, and hyphens.
They must start and end with a lowercase letter or digit.
The name is used as the workload identity in metadata, labels, backend
references, and generated resource names.

## Workload fields

A workload may contain:

| Field | Type | Behavior |
| --- | --- | --- |
| `replicas` | Integer, minimum `1` | Stable instance replica count; defaults to `1` and is forced to `1` for previews |
| `resources` | Kubernetes `ResourceRequirements` | Passed to the container |
| `env` | List of Kubernetes `EnvVar` | Passed to the container |
| `envFrom` | List of Kubernetes `EnvFromSource` | Passed to the container |
| `readinessProbe` | Kubernetes `Probe` | Rendered as the readiness probe |
| `http` | SCG HTTP configuration | Adds a container port, Service, and optional routing |
| `source` | Immutable source lock | Required for every rendered workload |
| `image` | Immutable image lock | Required for every rendered workload |

The chart does not expose container commands, arbitrary ports, liveness probes,
startup probes, volumes, volume mounts, service accounts, or arbitrary Pod
fields.

## `replicas`

```yaml
replicas: 3
```

The value must be an integer greater than or equal to `1`.
Production and testing Deployments use this value.
Preview Deployments always use one replica.

## `resources`

`resources` follows Kubernetes `ResourceRequirements`:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

Supported fields are:

- `requests`: a map of resource names to quantity strings;
- `limits`: a map of resource names to quantity strings; and
- `claims`: a list of resource claims.

A resource claim contains:

- `name`: required string;
- `request`: optional string.

The schema accepts arbitrary resource-name keys and quantity strings; Kubernetes
performs the resource-specific validation.

## `env`

```yaml
env:
  - name: LOG_LEVEL
    value: info
  - name: PORT
    value: "8080"
```

Each item requires `name` and may contain `value` or `valueFrom`.

`valueFrom` supports:

- `configMapKeyRef`: `key` is required; `name` and `optional` are optional;
- `secretKeyRef`: `key` is required; `name` and `optional` are optional;
- `fieldRef`: `fieldPath` is required; `apiVersion` is optional;
- `resourceFieldRef`: `resource` is required; `containerName` and `divisor` are optional;
- `fileKeyRef`: `volumeName`, `path`, and `key` are required; `optional` is optional.

Examples:

```yaml
env:
  - name: LOG_LEVEL
    valueFrom:
      configMapKeyRef:
        name: shop-config
        key: LOG_LEVEL
  - name: API_TOKEN
    valueFrom:
      secretKeyRef:
        name: shop-secrets
        key: API_TOKEN
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
```

Environment values are strings.
Quote values that would otherwise be parsed by YAML as numbers or booleans.

The chart does not create volumes, so `fileKeyRef` cannot reference a volume
created through application metadata alone.

## `envFrom`

```yaml
envFrom:
  - configMapRef:
      name: shop-config
  - secretRef:
      name: shop-secrets
    prefix: SHOP_
```

Each item may contain:

- `prefix`: optional string;
- `configMapRef`, containing optional `name` and `optional`; or
- `secretRef`, containing optional `name` and `optional`.

The values are passed directly to the container's Kubernetes `envFrom` field.
When managed Vault integration is enabled, its optional generated Secret source
is rendered first and these sources follow it.

## Managed Vault environment

Managed Vault integration is internal platform behavior and has no workload
field in `meta.yaml`. When centrally enabled, every rendered workload gets:

- a generated ExternalSecret;
- an optional `envFrom` reference to `<application>-<workload>-environment`;
- a namespaced SecretStore using the shared Vault application role; and
- automatic rollout annotations for Secret changes.

Stable instances extract one logical KV v2 path:

```text
applications/<application>/<instance-type>/<workload>
```

Preview instances merge testing and preview paths in order:

```text
applications/<application>/testing/<workload>
applications/<application>/preview/<workload>
```

Vault keys become environment variable names directly. Use portable names such
as `DATABASE_URL`. A missing Vault path leaves the Kubernetes Secret absent and
the optional environment source contributes no variables.

The ApplicationSets centrally enable this integration after Vault's storage,
TLS, initialization, and shared application role are ready. The design and
activation procedure are in the [Vault component README](../../platform/vault/README.md).

## `readinessProbe`

`readinessProbe` is a Kubernetes `Probe` rendered on the container.
The chart supports the following timing fields:

- `initialDelaySeconds`;
- `periodSeconds`;
- `timeoutSeconds`;
- `successThreshold`;
- `failureThreshold`; and
- `terminationGracePeriodSeconds`.

Supported handlers are `exec`, `grpc`, `httpGet`, and `tcpSocket`.

### HTTP probe

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: http
  periodSeconds: 10
```

`httpGet` supports:

- `host`: optional string;
- `path`: optional string;
- `port`: required integer or named-port string;
- `scheme`: optional string; and
- `httpHeaders`: optional list of required `name` and `value` pairs.

The generated HTTP container port is named `http`, so a probe may use
`port: http`.

### TCP probe

```yaml
readinessProbe:
  tcpSocket:
    port: 8080
```

`tcpSocket` supports optional `host` and required integer or named `port`.

### Exec probe

```yaml
readinessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - test -f /tmp/ready
```

`command` is a list of strings.

### gRPC probe

```yaml
readinessProbe:
  grpc:
    port: 9090
    service: health
```

`grpc.port` is required. `service` is optional.

The chart does not expose liveness or startup probes.
Kubernetes applies its normal defaults and semantic validation to the probe.

## `http`

```yaml
http:
  port: 8080
```

`http.port` is required and must be an integer from `1` through `65535`.

Adding `http` creates:

- a container port named `http` using the configured container port;
- a ClusterIP Service named `<application>-<workload>`;
- Service port `80` targeting the named `http` port;
- TCP protocol; and
- `appProtocol: http`.

A workload without `http` receives no Service and no container port.

## `http.domain`

A domain is either:

- one hostname string;
- one `{name, external}` object; or
- a non-empty, unique list of either form.

Hostnames must be 1 to 253 characters, use lowercase DNS labels, and have no
wildcards, underscores, uppercase letters, or trailing dot.
Each label is at most 63 characters.

String form:

```yaml
domain: shop.example.org
```

Object form:

```yaml
domain:
  name: shop.example.org
  external: false
```

The object requires both `name` and `external` and rejects additional fields.

List form:

```yaml
domain:
  - shop.example.org
  - name: legacy.example.org
    external: true
```

### Production domains

Production creates one ListenerSet and HTTPRoute per domain.

A string domain is treated as `external: false`:

- listener protocol: HTTPS;
- listener port: `443`;
- a cert-manager Certificate is created; and
- the route is not marked for ExternalDNS exclusion.

For each workload and hostname, the chart uses the first eight characters of
`sha256(hostname)` as a suffix:

```text
<application>-<workload>-<sha256-hostname-prefix>
```

Long results preserve a readable prefix and append a stable hash. The base name
is limited to 59 characters so its `-tls` derivatives also remain within the
63-character limit. The ListenerSet and HTTPRoute use that name.
A non-external domain also creates a Certificate and TLS Secret with `-tls`
appended.

An external domain uses:

- listener protocol: HTTP;
- listener port: `80`;
- no Certificate; and
- the ExternalDNS exclusion annotation.

Use `external: true` when DNS and TLS termination are managed outside the
platform.

### Testing and preview domains

Testing and preview instances use the platform's wildcard DNS records and
wildcard HTTPS listeners. Their routes retain instance-specific hostnames for
Gateway matching, but ExternalDNS publishes only the platform wildcard:

```text
Testing route: <application>.testing.scg.sh
Testing DNS:   *.testing.scg.sh
Preview route: <application>-<workload>-<pull-request>.preview.scg.sh
Preview DNS:   *.preview.scg.sh
```

No per-instance Certificate is created. The `external` value does not change
testing or preview listener behavior.

## `http.rules`

`rules` is an optional non-empty list of Gateway API `HTTPRouteRule` objects.
If `rules` is present, `domain` is required.

```yaml
http:
  port: 8080
  domain: shop.example.org
  rules:
    - name: api
      matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: api
          port: 80
```

A rule may contain:

- `name`;
- `matches`;
- `filters`;
- `backendRefs`; and
- `timeouts`.

### Rule name

`name` is optional and must be a 1 to 253 character lowercase DNS-style name.
If omitted, the chart generates:

```text
<application>-<workload>-<rule-number>
```

For example:

```text
shop-web-1
```

### Matches

`matches` may contain up to 64 entries.
If omitted, Gateway API defaults to a catch-all path-prefix match for `/`.

Each match may contain:

- `path`;
- `headers`;
- `queryParams`; and
- `method`.

`path.type` is one of `Exact`, `PathPrefix`, or `RegularExpression`.
The default is `PathPrefix` with value `/`.

Headers and query parameters contain required `name` and `value` fields.
Their type is `Exact` or `RegularExpression`, defaulting to `Exact`.
Each list allows up to 16 entries.

`method` supports:

```text
GET, HEAD, POST, PUT, DELETE, CONNECT, OPTIONS, TRACE, PATCH
```

For `Exact` and `PathPrefix` paths, Gateway API validates that the path is
absolute and does not contain invalid traversal or encoding patterns.

### Backend references

`backendRefs` may contain up to 16 entries.

Each backend reference supports:

- `name`: required string;
- `group`: optional, default empty group;
- `kind`: optional, default `Service`;
- `namespace`: optional namespace;
- `port`: optional integer from `1` through `65535`;
- `weight`: optional integer from `0` through `1,000,000`, default `1`; and
- `filters`: optional Gateway API backend filters.

Application-local Service references use workload keys:

```yaml
backendRefs:
  - name: api
```

The chart converts that to the generated Service name:

```text
<application>-api
```

It also defaults the local Service port to `80`.
References with an explicit namespace, non-empty group, or non-`Service` kind
are passed through unchanged.

If `backendRefs` is omitted and the rule is not redirect-only, the chart
creates a reference to the owning workload's Service on port `80`.

### Filters

A rule may contain up to 16 filters.
Each filter requires `type` and supports one of:

- `RequestHeaderModifier`;
- `ResponseHeaderModifier`;
- `RequestMirror`;
- `RequestRedirect`;
- `URLRewrite`;
- `ExtensionRef`; or
- `CORS`.

Request and response header modifiers support `add`, `set`, and `remove`.
`add` and `set` allow up to 16 `{name, value}` entries; `remove` allows up to 16
header names.

A request mirror requires `backendRef` and either:

- `percent`, from `0` through `100`; or
- `fraction`, with a non-negative `numerator` and a positive `denominator`.

The fraction denominator defaults to `100`, and the numerator cannot exceed it.
Percent and fraction cannot both be used.

A request redirect supports:

- `hostname`;
- `port`;
- `scheme`, either `http` or `https`;
- `statusCode`, one of `301`, `302`, `303`, `307`, or `308`, default `302`; and
- `path` replacement using `ReplaceFullPath` or `ReplacePrefixMatch`.

A URL rewrite supports `hostname` and the same path replacement forms.

An extension reference requires `group`, `kind`, and `name`.

CORS supports:

- `allowCredentials`;
- up to 64 `allowHeaders`;
- up to 9 `allowMethods`;
- up to 64 `allowOrigins`;
- up to 64 `exposeHeaders`; and
- `maxAge`, default `5`.

The wildcard value cannot be combined with other values in the relevant CORS
lists.
Filter types cannot be repeated, and `RequestRedirect` cannot be used together
with `URLRewrite`.

A rule containing `RequestRedirect` without `backendRefs` remains redirect-only;
the chart does not add its default Service backend.

### Timeouts

```yaml
timeouts:
  request: 30s
  backendRequest: 25s
```

Supported fields are `request` and `backendRequest`.
Values use Gateway API duration syntax, such as `10s`, `1m`, or `1m30s`.
When both are supplied, `backendRequest` cannot exceed `request` unless the
request timeout is zero.

## Immutable locks

### `source`

```yaml
source:
  repository: https://github.com/example/shop.git
  revision: 0123456789abcdef0123456789abcdef01234567
```

`source` requires exactly `repository` and `revision`.

The repository must be an HTTPS URL ending in `.git`, without credentials, query
parameters, or fragments.
The revision must be a full lowercase 40-character hexadecimal Git SHA.

### `image`

```yaml
image: registry.example.org/example/shop@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

The image must be a fully qualified lowercase OCI reference with:

- a `localhost` or DNS registry host;
- an optional numeric registry port;
- a repository path; and
- a lowercase 64-character SHA-256 digest.

Mutable tags such as `nginx:latest` are rejected. `source` and `image` are a
pair: if either is supplied, both are required.

## Internal context

ApplicationSets inject `_context`; application metadata should not define it.

```yaml
_context:
  application: shop
  instance:
    type: production
  secrets:
    enabled: false
```

`application` must be a valid workload-style name. `instance.type` is one of
`production`, `testing`, or `preview`. The optional `secrets` object is supplied
only by the platform. Enabling it also requires an HTTPS `server` URL; application
metadata must not define either field.

Preview context additionally requires:

```yaml
instance:
  type: preview
  workload: web
  pullRequest: 42
```

`workload` must be a valid workload name. `pullRequest` must be an integer at
least `1`.
Production and testing contexts must not include `workload` or `pullRequest`.

## Rendering by instance type

### Production

- all workloads are rendered;
- every workload needs a source and image lock;
- configured replicas are used;
- each domain gets production routing resources; and
- non-external domains receive HTTPS and certificates.

### Testing

- all workloads are rendered;
- every workload needs a source and image lock;
- configured replicas are used; and
- workloads with domains route through `<application>.testing.scg.sh`.

### Preview

- only the selected workload is rendered;
- only the selected workload needs a source and image lock;
- replicas are forced to `1`;
- the hostname includes application, workload, and pull request;
- references to other local workloads target testing Services; and
- a cross-namespace `ReferenceGrant` may be created as
  `<application>-<workload>-<pull-request>` in `<application>-testing`.

## Local rendering

From the repository root:

```bash
helm template example-production argocd/charts/application \
  --values applications/example/meta.yaml \
  --values applications/example/instances/production.yaml \
  --set _context.application=example \
  --set _context.instance.type=production
```

Inspect Deployments, Services, routes, certificates, namespaces, and image
locks.
Do not apply rendered output to a cluster for ordinary validation.

## Generated schema

Do not edit `values.schema.json` directly.
Edit [`values.schema.source.json`](values.schema.source.json), then regenerate
and check the output:

```bash
k generate application-schemas
k generate application-schemas --check
```

The generated schema incorporates the Kubernetes and Gateway API definitions
pinned in `state.yaml`.
