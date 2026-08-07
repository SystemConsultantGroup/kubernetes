# SCG Application Platform Specification

Status: approved design specification; not yet operationally authoritative.

This document defines the strict registry, lock, and Helm rendering contracts for ordinary SCG applications. The paper port in `working/applications/` is the evidence and pressure-test basis (`working/applications/README.md` is the index). The implementation must reject unsupported or ambiguous input rather than silently guessing.

## 1. Scope

The platform supports ordinary stateless application workloads that can be represented as:

- one or more container images;
- one Deployment per workload;
- an optional ClusterIP Service per workload;
- optional HTTP routing;
- literal environment variables and references to existing Kubernetes Secrets;
- resource and replica deviations;
- TCP or HTTP readiness checks.

A workload with no `port` is a long-running worker Deployment. A workload with a `port` gets a Service on port 80 targeting that container port. A route exposes such a Service through the shared Gateway.

The application chart does not support CronJobs, one-shot migrations, databases, Redis, persistent volumes, custom commands, arbitrary manifests, RBAC, service accounts, scheduling controls, or stateful/platform software. Those remain platform components or receive a dedicated chart when an active application proves the need.

## 2. Authoritative sources

The public `SystemConsultantGroup/kubernetes` repository is the sole desired-state source.

- Argo CD UI changes are non-authoritative and must not be used for persistent configuration.
- Application repositories contain code, Dockerfiles, and a small caller for the central reusable workflow.
- Application workflows publish immutable images and submit attested lock-mutation requests; the central lock writer is the only non-human authority that edits registry locks in this repository.
- Argo CD receives a webhook for this repository and polls as a fallback.
- Argo CD refreshes after a Git change, renders desired resources, and syncs only when rendered resources differ from live resources.
- Argo CD Image Updater is removed once the lock-writing workflow is operational. There must be one image-revision writer.

## 3. Repository layout

```text
.github/
  workflows/
    publish-application-image.yaml  # reusable workflow_call workflow
lock-writer/                         # Cloudflare Queue consumer and submission API
applications/
  <application>/
    meta.yaml                       # human-managed intent
    lock.yaml                       # workflow-managed immutable state
    routes/                         # only when routes: custom
      kustomization.yaml
      *.yaml
argocd/
  applicationsets/
  generated/
    releases.yaml                 # generated flat release index
  charts/
    application/
      Chart.yaml
      values.yaml
      values.schema.json
      templates/
  platform/
```

The application directory basename is the application name. It must be a lowercase DNS label, and every derived hostname, namespace, Argo Application name, and resource name must remain within the Kubernetes 63-character limit.

## 4. Environments and names

Every registered workload has a production branch. Testing is optional, but an application either declares a testing branch for every workload or for none; partial testing applications are invalid. Branch names remain per workload because component repositories may use different conventions.

| Environment | Source | Namespace | Hostname |
| --- | --- | --- | --- |
| Production | `workloads.<name>.branches.production` | `app-production-<application>` | production `domain` |
| Testing | all workloads declare `branches.testing` | `app-testing-<application>` | `<application>.testing.scg.sh` |
| Preview | eligible labeled pull request | `app-preview-<application>-<anchor>-<number>` | `<application>-<anchor>-<number>.preview.scg.sh` |

Applications without testing branches have no testing release. They may still create previews from pull requests targeting production.

PR numbers are repository-scoped, so preview identity includes a repository anchor: the lexicographically first application workload backed by the pull request repository. One application/repository/pull-request tuple produces one preview, even when the trusted build publishes several workloads from that repository. Each preview is a complete immutable snapshot of every application workload; workloads absent from the atomic mutation request are copied from the pull request target environment.

Testing and preview infrastructure is static platform policy:

- wildcard DNS records for `*.testing.scg.sh` and `*.preview.scg.sh` point to the shared Gateway;
- two static HTTPS Gateway listeners serve those zones;
- one Certificate contains both wildcard SANs;
- testing and preview namespaces are restricted to the organization source CIDRs by central Cilium policy;
- preview namespaces additionally deny private/cluster-network egress and Kubernetes API access by default;
- application Pods do not receive service-account tokens;
- applications cannot override these access policies.

The fixed policies must be validated against the source addresses Cilium observes after load-balancer and school-firewall NAT. Applications requiring preview access to private dependencies are unsupported until the platform defines a narrow trusted exception mechanism.

## 5. Strict `meta.yaml` contract

Unknown fields and duplicate YAML mapping keys at every level are errors. Strict parsing rejects duplicates before schema validation. YAML aliases, merge keys, and environment interpolation are not part of the contract. Values have the types shown below; strings are not coerced from numbers or booleans.

### 5.1 Complete synthetic example

The names and values below illustrate the schema only; they are not migration evidence for an existing application.

```yaml
workloads:
  fe:
    repository: https://github.com/SystemConsultantGroup/example-frontend.git
    image: docker.io/scgskku/example-fe-prod
    branches:
      testing: dev
      production: main
    port: 3000
    readiness:
      type: tcp

  be:
    repository: https://github.com/SystemConsultantGroup/example-backend.git
    image: docker.io/scgskku/example-be-prod
    branches:
      testing: dev
      production: main
    port: 8000
    readiness:
      type: http
      path: /health/ready
    replicas:
      testing: 1
      production: 2
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        memory: 512Mi
    env:
      literals:
        LOG_LEVEL: info
      from:
        secrets:
          - example-secret

domain:
  name: example.cs.skku.edu
  external: true
  additional:
    - example-old.scg.sh
    - name: example2.cs.skku.edu
      external: true

routes:
  - path: /
    workload: fe
  - path: /v1
    workload: be
```

### 5.2 Top-level fields

| Field | Required | Type | Meaning |
| --- | --- | --- | --- |
| `domain` | when `routes` exists | `string \| Domain` | Canonical production hostname and optional additional production hostnames. |
| `workloads` | yes | non-empty map of `Workload` | Deployment definitions keyed by local DNS-label workload names such as `fe`, `be`, `api`, or `worker`. |
| `routes` | no | `custom \| GeneratedRouteRule[]` | Omitted for no public HTTP routing, a list of chart-specific generated-route rules, or `custom` for constrained Gateway API HTTPRoutes. |

No other top-level fields are allowed.

#### Application boundaries

Workloads that form one product and share a production hostname and route set belong in one application. This permits generated rules such as frontend `/` plus backend `/v1` without competing hostname ownership.

Split workloads into separate applications when they require different production hostname route sets or independent release ownership. Reusing one repository in several applications or workloads is allowed. Reusing one production hostname across applications is not. Because non-production custom routes are collapsed onto one derived hostname, host-separated production components normally remain separate applications unless their combined testing and preview routing is intentional and unambiguous.

### 5.3 Domain

A string is shorthand for a platform-managed production domain:

```yaml
domain: example.scg.sh
```

Equivalent object form:

```yaml
domain:
  name: example.scg.sh
  external: false
```

Strict non-recursive shape:

```text
Domain:
  name: hostname                       required
  external: boolean                    required
  additional: AdditionalDomain[]       optional, default []

AdditionalDomain:
  string                               managed shorthand
  or:
    name: hostname                     required
    external: boolean                  required
```

`additional` is deliberately not recursive. Additional domains cannot contain additional domains; recursion would add no behavior and would permit ambiguous trees and duplicates.

All primary and additional names must be unique valid lowercase DNS hostnames. Hostname ownership is globally unique across the complete application registry; two applications cannot claim the same primary or additional hostname. The platform reserves the complete `testing.scg.sh` and `preview.scg.sh` subtrees, so production domains cannot fall beneath either zone. Managed hostnames must belong to an explicitly configured and operational ExternalDNS zone.

Managed domain behavior (`string` or `external: false`):

- create an exact DNS record through ExternalDNS;
- create an exact HTTPS listener;
- request certificate coverage through cert-manager;
- route HTTPS traffic through the shared Gateway.

External domain behavior (`external: true`):

- do not create or mutate DNS;
- do not request a Certificate;
- create an exact HTTP listener on port 80;
- mark generated HTTPRoutes so ExternalDNS ignores them;
- do not redirect HTTP to HTTPS;
- expect the school firewall to own the public DNS/TLS path and forward HTTP while preserving the Host header.

External listeners must accept only the observed school-firewall source ranges to prevent direct bypass. Registration remains blocked until those ranges and post-NAT behavior are validated.

Additional domains exist only in production. Testing and preview always use the platform wildcard zones.

### 5.4 Workload

```text
Workload:
  repository: string                   required
  image: string                        required
  branches: Branches                   required
  port: integer                        optional, 1..65535
  readiness: Readiness                 optional
  replicas: Replicas                   optional
  resources: Resources                 optional
  env: Environment                     optional
```

No other workload fields are allowed.

#### Repository

`repository` is a canonical HTTPS Git clone URL:

```yaml
repository: https://github.com/SystemConsultantGroup/example.git
```

Requirements:

- exact form `https://github.com/SystemConsultantGroup/<repository>.git` for v1;
- no embedded credentials, query, fragment, or trailing slash;
- `.git` suffix;
- no GitHub `owner/repository` shorthand;
- exact equality is used when validating workflow and lock updates.

Other Git hosts or owners require a later workflow and authorization contract; a syntactically valid external URL is not accepted by v1.

#### Image

`image` is a fully qualified OCI image repository without a tag or digest:

```yaml
image: ghcr.io/systemconsultantgroup/example
image: docker.io/scgskku/example
image: registry.scg.skku.ac.kr/team/example
```

The registry is mandatory. `docker.io`, GHCR, Harbor, and other registries are not inferred from the Git repository. Image path components must use their canonical lowercase form.

#### Branches

```yaml
branches:
  production: main
  testing: dev
```

`production` is required. `testing` is optional. Both values are non-empty Git branch names and must differ when testing is present. Within one application, testing must be declared by every workload or by none.

#### Port and Service

- No `port`: Deployment only; the workload is not routable and receives no Service.
- `port`: Deployment plus ClusterIP Service port 80 targeting the declared container port.
- A generated route may reference only a workload with a port.
- Services use the workload key as their stable local name.

#### Readiness

A workload with a port defaults to TCP readiness on that port. It may explicitly select:

```yaml
readiness:
  type: tcp
```

or:

```yaml
readiness:
  type: http
  path: /health/ready
```

Rules:

- `type` is exactly `tcp` or `http`;
- `path` is required for HTTP and forbidden for TCP;
- the workload port is always used and cannot be overridden;
- readiness timing, thresholds, headers, and schemes are central chart policy;
- readiness is forbidden when the workload has no port;
- the chart does not generate liveness or startup probes.

#### Replicas

```yaml
replicas:
  testing: 1
  production: 3
```

Both values are optional positive integers. Omitted stable values default to one. Preview replicas are always one and cannot be configured.

#### Resources

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: "1"
    memory: 512Mi
```

Only `requests` and `limits`, each containing only `cpu` and/or `memory`, are allowed. Omitted entries use central chart defaults. Kubernetes quantity validation occurs during schema/render validation.

#### Environment

```yaml
env:
  literals:
    LOG_LEVEL: info
  from:
    secrets:
      - application-config
```

Rules:

- `literals` is a map of valid environment-variable names to string values;
- `from.secrets` is a unique list of same-namespace Kubernetes Secret names;
- the chart renders Secret names through native `envFrom.secretRef`;
- Secret values never appear in `meta.yaml` or `lock.yaml`;
- missing non-optional Secrets prevent the Pod from starting;
- secret provisioning and rotation are external platform responsibilities;
- changing a Secret does not change an existing process environment without a rollout.

Only `literals` and `from.secrets` are supported initially. Future `secretKeys` or `configMaps` require an evidence-backed schema revision; placeholders for them are not accepted now.

### 5.5 Generated routes

```yaml
routes:
  - path: /
    workload: fe
  - path: /api
    workload: be
```

Each list entry is chart-specific metadata, not a Gateway API `HTTPRoute` embedded as-is. The chart translates `GeneratedRouteRule` entries into rules within platform-owned `HTTPRoute` resources.

```text
GeneratedRouteRule:
  path: absolute HTTP path prefix       required
  workload: existing workload key       required
```

Fields such as `apiVersion`, `kind`, `metadata`, `hostnames`, `parentRefs`, filters, and raw Gateway API rules are invalid here. Applications needing actual Gateway API `HTTPRoute` resources use `routes: custom` instead.

Rules:

- the list must contain at least one route;
- match type is Gateway API `PathPrefix`;
- duplicate paths are forbidden;
- the referenced workload must have a port;
- the most specific path wins according to Gateway API precedence;
- testing and preview emit one HTTPRoute using only their derived platform hostname;
- production emits one HTTPRoute per declared production domain so managed and external DNS behavior never shares one annotated resource;
- every emitted route contains the same generated path rules.

Generated routes do not expose rewrites, redirects, CORS, regular expressions, headers, mirrors, weights, or arbitrary annotations.

### 5.6 Custom routes

```yaml
routes: custom
```

This requires `applications/<application>/routes/` and disables generated HTTPRoute rendering.

Strict custom-route contract:

- only namespaced `gateway.networking.k8s.io` `HTTPRoute` resources are allowed;
- Gateways, ListenerSets, Certificates, Services, Deployments, policies, Secrets, RBAC, and cluster-scoped resources are forbidden;
- source `metadata.namespace` and `spec.parentRefs` are forbidden; the platform injects and overwrites the release namespace and exact parent;
- every source HTTPRoute must contain a non-empty production `hostnames` list that is a subset of the declared primary and additional production domains;
- one production HTTPRoute cannot mix managed and external hostnames; the platform applies ExternalDNS-ignore only to external-domain routes;
- the platform always overwrites non-production `hostnames` with the one exact derived testing or preview hostname; omission cannot match the whole wildcard listener;
- backend references may target only Services generated for local declared workloads on Service port 80;
- cross-namespace backend references and `ExtensionRef` filters are forbidden;
- source annotations are forbidden except `platform.scg.sh/production-only: "true"`;
- routes carrying that annotation are omitted from testing and previews;
- v1 custom-route filters are limited to core `RequestRedirect` and `URLRewrite`; CORS, header modifiers, mirrors, and implementation-specific filters remain unsupported until their semantics and Cilium conformance are proven;
- every rendered route must pass Gateway API schema validation and Cilium conformance tests before migration.

The implementation must prove the Kustomize/multi-source injection and resource allowlist before the first custom-route migration. Custom routing is not an arbitrary Kubernetes escape hatch.

## 6. Strict `lock.yaml` contract

`lock.yaml` is committed desired state. It is normally workflow-managed but remains human-editable for recovery. Unknown fields are errors.

```yaml
lock:
  version: 1

  environments:
    testing:
      workloads:
        fe:
          sourceRevision: "0123456789abcdef0123456789abcdef01234567"
          imageDigest: sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
        be:
          sourceRevision: "89abcdef0123456789abcdef0123456789abcdef"
          imageDigest: sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

    production:
      workloads:
        fe:
          sourceRevision: "1111111111111111111111111111111111111111"
          imageDigest: sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
        be:
          sourceRevision: "2222222222222222222222222222222222222222"
          imageDigest: sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

  previews:
    fe-42:
      workload: fe
      pullRequest: 42
      targetEnvironment: testing
      workloads:
        fe:
          sourceRevision: "3333333333333333333333333333333333333333"
          imageDigest: sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
        be:
          sourceRevision: "89abcdef0123456789abcdef0123456789abcdef"
          imageDigest: sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
```

Rules:

- `lock.version` is exactly `1`;
- `production` is required; `testing` is required exactly when every metadata workload declares `branches.testing`; `previews` is optional and defaults to an empty map;
- every stable and preview snapshot contains exactly every metadata workload key;
- no lock workload may be absent from or additional to `meta.yaml`;
- `sourceRevision` is a quoted string containing the full 40-character lowercase Git commit SHA;
- `imageDigest` is exactly `sha256:` followed by 64 lowercase hexadecimal characters;
- the rendered image is `<meta workload image>@<imageDigest>`;
- workflow validation verifies the digest exists and its workflow-bound provenance matches the registered repository and `sourceRevision`;
- a stable mutation must originate from the corresponding registered branch and contain a non-empty set of workload updates;
- one mutation may update several workloads atomically only when all changed workloads are registered to the same source repository and were built from the same source revision by one trusted workflow run;
- stable sibling workload entries absent from the mutation must remain unchanged;
- preview keys are exactly `<anchor>-<number>` and unique, with a positive integer pull-request number; `anchor` is the lexicographically first application workload registered to the pull request repository;
- each preview's `workload` field contains that anchor and the key must equal it plus `-` plus `pullRequest`;
- `targetEnvironment` is exactly an available `testing` or `production` environment; the PR base ref must equal every changed workload's registered branch for that environment;
- every changed preview workload's `sourceRevision` must equal the PR head commit and all changed workloads must belong to the pull request repository;
- preview snapshots are complete, not deltas; at creation, workloads absent from the atomic mutation are copied from the selected target-environment lock; on later updates, workloads absent from the mutation remain equal to the previous preview snapshot, so stable updates never cause an existing preview to drift;
- removing the preview label or closing the pull request removes its lock entry;
- manual changes pass the same validation as workflow changes.

A PR that updates several workloads from one repository creates one atomic repository-scoped preview. Separate repositories can still produce separate previews because their pull requests and source revisions are independent.

## 7. Reusable image workflow contract

The reusable workflow lives at:

```text
SystemConsultantGroup/kubernetes/.github/workflows/publish-application-image.yaml
```

Each application repository contains only a small event/caller workflow. One invocation targets exactly one application and takes a non-empty list of workload, Dockerfile, and build-context tuples; v1 does not auto-discover monorepo build targets. A single-workload application supplies a one-entry list. One trusted workflow run builds the complete list and submits all resulting workload updates in one mutation. A repository publishing workloads for several applications invokes the workflow separately for each application.

Build-time configuration is a CI concern, not chart metadata. Non-secret build values come from the selected GitHub `testing` or `production` environment variables. Build secrets use BuildKit secret mounts from the matching GitHub environment and must not be passed as Docker build arguments or persisted in image layers. Preview builds receive only explicitly approved preview-safe values and never production build secrets. Applications whose frontend or backend build cannot follow this contract are blocked from migration.

The workflow separates trust domains:

1. an unprivileged job checks out and tests/builds application code without Kubernetes-repository or GitHub App credentials;
2. a publisher job consumes only the resulting immutable build output, publishes the configured canonical image, and creates workflow-bound provenance/attestation for the source repository, commit, workflow, and digest;
3. a trusted submitter verifies local build outputs and emits an immutable, idempotent lock-mutation request containing one or more same-repository workload updates, their attestations, the target application/environment, and the compare-and-swap expectations defined below;
4. one central lock writer serializes requests per application, re-verifies provenance and authorization against `meta.yaml`, applies the complete mutation atomically, regenerates the release index, and proposes the Git change through its narrowly permissioned GitHub App;
5. no publisher or untrusted application job receives lock-writing credentials, and no automated identity other than the central lock writer may edit `lock.yaml`.

V1 uses a Cloudflare Queue owned by this repository. Application workflows receive only submit authority and enqueue immutable mutation objects; the queue consumer Worker holds the GitHub App credential and is the sole automated lock writer. The consumer runs with global concurrency one and processes each delivered batch sequentially.

The writer maintains one pending lock-update branch and pull request. It reads that branch when present, otherwise the authoritative branch; applies and validates one mutation; commits the mutation plus regenerated release index; and acknowledges the queue message only after Git durably contains that proposal. Later messages extend the same branch, so automation never creates competing lock proposals. CI or a human merges the accumulated proposal; a failed check or merge leaves the mutation durably pending rather than silently delivered. Queue retries and a dead-letter queue cover failures before the proposal commit. Add a Durable Object only if measured throughput or pending-branch coordination outgrows this globally serialized design.

Each request has a unique mutation ID. Every changed workload includes its expected current lock entry and desired replacement; preview creation additionally includes the expected target-environment snapshot hash. The writer applies an exact compare-and-swap: an already-identical desired result is a successful no-op, an exact expected match is updated, and any other state is rejected as stale without automatic rebasing. A newly submitted request may reuse the verified build outputs with refreshed expectations. Human recovery edits remain allowed and pass the same validation.

Testing and production branch pushes update their matching stable snapshots when that branch is registered. Eligible maintainer-labeled pull requests update one repository-scoped preview snapshot. Central CI validates schema, attested provenance, authorization, Helm rendering, and changed-file scope before merge. Production lock updates follow the established production-branch merge procedure.

## 8. Helm release inputs

Argo supplies the chart with:

- application name derived from the registry directory;
- release environment (`production`, `testing`, or a preview key);
- `meta.yaml`;
- `lock.yaml`;
- the central chart defaults.

Helm does not discover sibling files. The generated Argo Application explicitly supplies both registry files as values sources. The chart selects one complete lock snapshot for the requested release and must fail rendering if it cannot resolve every workload.

A deterministic registry compiler flattens all stable and preview lock snapshots into `argocd/generated/releases.yaml`. A native Git-plus-List matrix generator consumes that list through `elementsYaml`, producing one Argo Application per release without a custom ApplicationSet plugin or map iteration. Every lock-changing PR regenerates the index; CI rejects a missing or stale generated file. Manual lock recovery therefore runs the same repository generator before commit.

Preview lock entries are created only for maintainer-labeled pull requests. Closing a PR or removing the label removes its lock entry and regenerated release entry; a scheduled central reconciliation workflow repairs missed close/label events. ApplicationSet discovers releases only from the generated index, while each generated Application still reads its registry metadata and lock as Helm values.

The chart's `values.schema.json` validates the merged metadata, lock, application name, and release selector with `additionalProperties: false`. CI also validates `meta.yaml` and `lock.yaml` independently so chart defaults cannot hide missing registry input.

## 9. Rendered resource contract

For each workload, the chart renders:

- one Deployment;
- one ClusterIP Service only when `port` exists;
- standard recommended Kubernetes labels;
- restricted pod and container security defaults;
- `automountServiceAccountToken: false`;
- immutable digest image reference;
- `IfNotPresent` image pull policy;
- readiness as specified;
- central resources unless overridden;
- literal environment variables and native Secret references.

Per release, the chart renders:

- one generated HTTPRoute per active hostname when `routes` is a list;
- no HTTPRoute when routes are omitted or custom;
- a production ListenerSet for routed production releases only;
- no ListenerSet or Certificate for testing or previews.

Production ListenerSet behavior:

- one exact HTTPS listener for each managed production domain;
- one exact HTTP listener for each external production domain;
- managed listeners reference cert-manager-created TLS material;
- external listeners contain no TLS configuration;
- the production release is the sole ListenerSet owner.

Testing and preview HTTPRoutes attach directly to the shared static wildcard Gateway listener. Production HTTPRoutes attach to their local ListenerSet.

The chart never renders Namespace resources. Generated Argo Applications use `CreateNamespace=true` and `managedNamespaceMetadata` for:

- environment identity;
- Gateway route selection;
- Pod Security Admission restricted labels;
- fixed testing/preview access-policy selection.

## 10. Security and validation invariants

Registration and lock CI must reject:

- unknown fields and duplicate YAML mapping keys;
- invalid, overlong, or globally colliding derived DNS/Kubernetes names;
- production domains beneath the reserved `testing.scg.sh` or `preview.scg.sh` zones;
- shorthand or credential-bearing repository URLs;
- image tags, image digests, or implicit registries in `meta.yaml`;
- equal testing and production branches when testing is declared, testing declared for only some application workloads, or `replicas.testing` declared when the application has no testing environment;
- duplicate or registry-conflicting domains, environment variables, Secret refs, or route paths;
- managed domains outside the configured ExternalDNS zone allowlist;
- routes referencing missing or portless workloads;
- a domain without routes or routes without a domain;
- readiness on a portless workload;
- HTTP readiness without a path or TCP readiness with a path;
- lock workload sets differing from metadata;
- malformed or unverified image digests and source revisions;
- unauthorized workflow changes to another application/workload/environment;
- custom route resource kinds or references outside the allowlist;
- production, testing, or preview sources attempting to own infrastructure or escape their generated namespace.

Generated Applications use hard-coded restrictive AppProjects. Preview sources must not receive production Secrets and cannot create cluster-scoped resources, RBAC, Gateways, ListenerSets, Certificates, policies, cross-namespace references, or unrestricted private-network/Kubernetes-API egress.

## 11. Secret provisioning

`env.from.secrets` references ordinary same-namespace Kubernetes Secrets. The application chart does not choose or expose a secret backend.

A separate platform implementation must provision those Secrets in every available stable environment and eligible preview namespace before an application is migrated. The selected backend must reconcile to native Kubernetes Secrets. Provider paths and production-secret access remain trusted platform configuration, not pull-request-controlled application values.

## 12. Deliberate exclusions

The first chart version excludes:

- CronJobs and Jobs;
- init containers and migration hooks;
- liveness and startup probes;
- commands and arguments;
- arbitrary annotations, labels, or pod specs;
- ConfigMap generation;
- individual Secret-key mappings;
- volumes and persistence;
- Redis and databases;
- autoscaling and PDBs;
- service accounts and RBAC;
- affinity, tolerations, topology spread, and node selection;
- arbitrary Gateway API kinds and extension filters;
- configurable testing/preview access policy;
- application-controlled namespaces, domains for non-production, DNS, TLS, or Gateway ownership.

Add a capability only when an active ordinary application proves it cannot be represented safely without it.

## 13. Implementation and migration order

1. Create strict independent metadata and lock schemas plus merged Helm `values.schema.json`.
2. Implement the deterministic flat release-index generator and stale-output CI check.
3. Add fixtures for a single HTTP workload, FE/BE application, worker, internal Service, external production domain, managed production domain, and preview snapshot.
4. Implement and test the generic chart rendering contract.
5. Add the two static wildcard DNS records, Certificate SANs, and Gateway listeners.
6. Validate fixed Cilium source restrictions after NAT.
7. Implement the reusable image workflow, environment-scoped build inputs, isolated credential jobs, attestations, Cloudflare mutation queue/consumer, and scoped lock-update validation.
8. Replace Image Updater after the lock workflow is live.
9. Implement restrictive stable/preview AppProjects, ApplicationSets, service-account-token disabling, and preview network isolation.
10. Select and implement native Kubernetes Secret reconciliation before migrating an application that references Secrets.
11. Prove custom-route injection and allowlisting with the S-TOP rewrite and SCG homepage redirect before enabling `routes: custom`.
12. Migrate ICC Haedong first, then the remaining applications in the migration order in [`applications/README.md`](applications/README.md); a production-only application simply has no testing release.
13. Remove hello-world's static listeners/certificates and old application manifests only after the replacement path passes live HTTP, TLS, DNS, readiness, rollback, and webhook/polling tests.

## 14. Required implementation proofs

Before this approved design becomes operationally authoritative, demonstrate:

- schema rejection of every forbidden shape listed above;
- deterministic rendering from `meta.yaml` plus `lock.yaml` and deterministic regeneration of the flat release index;
- Git webhook refresh and polling fallback;
- stable single- and same-repository multi-workload atomic lock updates and rollback by Git revert;
- application/workload-scoped authorization, serialization, retry idempotency, and stale-revision handling for lock changes;
- repository-scoped PR preview creation, update, and deletion;
- shared wildcard testing/preview DNS and TLS;
- organization-only testing/preview access after real NAT;
- managed HTTPS and external HTTP-only production domains;
- exact hostname/parent injection and kind enforcement for custom HTTPRoutes;
- namespace and AppProject escape prevention;
- Secret availability before Deployment rollout;
- live readiness and traffic smoke tests.

## References

- Evidence/pressure-test basis: [`applications/README.md`](applications/README.md) (paper port index, migration order, and per-application `PORTING.md` evidence pointers); [`applications/EXCLUDED.md`](applications/EXCLUDED.md) records excluded platform/stateful/stale repositories
- Argo CD ApplicationSet Git generator: <https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/>
- Argo CD Pull Request generator: <https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Pull-Request/>
- Argo CD webhooks: <https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/>
- Gateway API ListenerSet: <https://gateway-api.sigs.k8s.io/guides/user-guides/listener-set/>
- cert-manager Gateway support: <https://cert-manager.io/docs/usage/gateway/>
- ExternalDNS Gateway source: <https://kubernetes-sigs.github.io/external-dns/latest/docs/sources/gateway-api/>
