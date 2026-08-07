# Legacy `*-config` sweep report

**Date/evidence basis:** 2026-08-07 snapshot. This is a read-only audit of all 23 `SystemConsultantGroup/*-config` repositories in `inventory.md` against [`APPLICATION_PLATFORM.md`](APPLICATION_PLATFORM.md). Legacy repositories are evidence only; this report does not migrate or create application directories.

## 1. Executive summary

The inventory contains 23 config repositories: 18 with verified SCG project repositories and 5 platform/third-party/tool repositories. One is private (`skku-alumni-config`); none is archived. The configs describe roughly 33 HTTP-facing workload instances plus Redis/monitoring/platform jobs (counts are workload instances, not repositories, and include stale/broken sources where noted).

The proposed chart is deliberately one image + one HTTP Service + generated HTTPRoute. It is a good direct fit for three simple single-workload applications:

- `ICC-haedong-seminar-reservation` (port 3000, one Secret)
- `ICC-lecture-enrollment` (port 8090, one Secret)
- `CSE-undergrad-gp-manage-v2` (port 8091, one Secret, but custom route for alias/annotation preservation)

Most remaining HTTP applications can be split into separate FE/BE registrations, but several require custom Gateway API routes, an image-publication decision, or a narrow/platform treatment. The strongest blockers are:

1. **Routing shape:** legacy nginx Ingress is universal in the audit. Many apps put FE `/` and BE `/v1` or `/api/v1` on one hostname, which the generated one-Service route cannot express.
2. **Image contract:** legacy images are overwhelmingly Docker Hub or internal Harbor, never the chart's default `ghcr.io/<lowercase owner/repo>`. Every proposed registration therefore needs an evidence-backed `image:` override, while tags must remain CI-controlled.
3. **Non-goal workloads:** Redis, PVC-backed codex-lb, monitoring, cloudflared, Renovate, Keycloak/SSO, and the office nginx stub are not ordinary generic-chart applications.
4. **DNS and TLS:** most canonical hosts are under `scg.skku.ac.kr`, `cs.skku.edu`, or `icc.skku.ac.kr`; current ExternalDNS configuration is restricted to `scg.sh`. A wildcard TLS SAN is not evidence of wildcard DNS.
5. **Evidence quality:** `PDF-config`, `cs-grad-thesis-config`, and the old `scg-new-2022-config` are stale or superseded; several overlays demonstrably fail to render. Live Argo/cluster state was not available.

No changes to `APPLICATION_PLATFORM.md`, source repositories, or legacy repositories are proposed as part of this report. Proposed platform changes are listed for later approval only.

## 2. Repository-to-project mapping

| Inventory indices | Config repository | Verified project(s) / classification | Evidence status |
|---|---|---|---|
| 0 | `CSE-undergrad-gp-manage-v2-config` | `SystemConsultantGroup/CSE-undergrad-gp-manage-v2` | active; Dockerfile + CD workflow |
| 1 | `ICC-grad-dissertation-manage-config` | `.../ICC-grad-dissertation-manage-backend`, `...-frontend` | prod-only; config last 2026-02-22 |
| 2 | `ICC-haedong-seminar-reservation-config` | `.../ICC-haedong-seminar-reservation` | active; Dockerfile + workflow |
| 3 | `ICC-lecture-enrollment-config` | `.../ICC-lecture-enrollment` | active; Dockerfile + workflow |
| 4 | `PDF-config` | `.../PDF-Converter-Module` | stale evidence; route/domain unknown |
| 5 | `S-TOP-config` | `.../S-top-backend`, `.../S-top-frontend` | prod + QA overlays; last 2026-05-14 |
| 6 | `SCG-Monitoring-Config` | none; kube-prometheus-stack platform | platform only |
| 7 | `SCG-SSO-config` | `.../SCG-SSO` | identity-provider candidate; last 2025-04-02 |
| 8 | `attendance-checker-config` | `.../attendance-checker-frontend`, `...-backend` | active; both workflows |
| 9 | `cloudflared-config` | none; Cloudflare tunnel | platform only |
| 10 | `codex-lb-config` | none; `ghcr.io/soju06/codex-lb` | third-party, PVC/custom command |
| 11 | `cs-grad-thesis-config` | `.../cs-grad-thesis-frontend`, `...-backend` | stale; no GitHub image workflows |
| 12 | `exhibition-config` | `.../exhibition-frontend`, `...-backend` | active; both workflows |
| 13 | `office-config` | none; nginx stub/probe | platform/placeholder |
| 14 | `ourlim-config` | `.../ourlim` (FE + BE Dockerfiles) | internal Harbor; no GitHub workflow |
| 15 | `renovate-config` | none; Renovate CronJob | platform tool |
| 16 | `room-reservation-config` | `.../room-reservation-frontend`, `...-backend` | active; prod + dev |
| 17 | `scg-apply-config` | `.../scg-apply-frontend`, `...-backend` | active-ish; prod + dev |
| 18 | `scg-home-config` | FE `.../scg-2026-frontend`; BE `.../SCG-new-2022` | current homepage source |
| 19 | `scg-new-2022-config` | `.../SCG-new-2022` | superseded by index 18 |
| 20 | `shortener-config` | `.../scg-url-shortener-frontend`, `...-backend` | active; prod + QA |
| 21 | `skku-alumni-config` | `.../skku-alumni-frontend` (user/admin images), `.../skku-alumni-backend` | private; active; Redis dependency |
| 22 | `timetable-planner-config` | `.../timetable-planner-frontend`, `...-backend` | active; Redis dependency |

Mapping was based on manifest image names plus project Dockerfiles and workflows, not name stripping. Important image-name drift includes `ice-gs-thesis-fe-prod`, `reservation-*`, `stop-*`, `shortener-*`, and `scg-home-*`.

## 3. Methodology and limitations

### Evidence reviewed

- `/home/scg/kubernetes/APPLICATION_PLATFORM.md`
- `/tmp/scg-legacy-sweep-6XxutiDo/inventory.md`
- The four supplied scan handoffs (lane 0 through lane 3), including their cited manifest, Dockerfile, workflow, branch, and render evidence.
- Read-only repository snapshots under `/tmp/scg-legacy-sweep-6XxutiDo/scan-{0,1,2,3}/repos/` where needed to validate the handoff context.

The expected files `/tmp/scg-legacy-sweep-6XxutiDo/scan-0.md` through `scan-3.md` were not present in the supplied filesystem; the four complete handoff texts were available in the task context and were used as the lane artifacts. This is recorded as a provenance limitation, not filled with guessed evidence.

### Interpretation rules

- Facts cite exact repository paths from the lane evidence; “inference” means behavior inferred from Dockerfile/application or chart shape, not observed runtime state.
- Secret values were not read or reproduced. Only Secret names and Vault/AVP-style placeholder mechanisms are recorded.
- Image tags are deployment evidence only. Metadata drafts intentionally omit tags because the platform says tags/digests remain automated.
- Existing nginx Ingress and cert-manager TLS annotations prove legacy intent, not that DNS, certificates, or live deployment currently work.
- “Active” means recent/default-branch evidence, not a cluster observation. Argo Applications for these configs were not found in the central `kubernetes`/`gitops` repositories.

### Render baseline

The handoffs report successful `kubectl kustomize`/`kustomize build` for all attempted overlays except these concrete defects:

- `scg-home-config` prod FE: duplicate `seminar-redirect-ingress` resource.
- `scg-home-config` prod BE: patch target `be-ingress` does not match base `scg-ingress-be`.
- `scg-new-2022-config` prod BE and FE: patch targets `be-ingress` and `fe-ingress` do not match the base resources; both base BE and FE render successfully.
- `SCG-Monitoring-Config`: Argo values path references `values/value.yaml`, while the tree contains `values/values.yaml`.

The remaining render attempts passed, including ICC, S-TOP, cloudflared, office, scg-apply, skku-alumni, ICC-haedong, codex-lb, ourlim, timetable, ICC-lecture, SCG-SSO, cs-grad-thesis, Renovate, and the scg-new-2022 base. Passing Kustomize parsing does not prove the resulting service, listener, Secret, or application works.

## 4. Cross-repository frequencies and chart-shape assessment

Counts below are evidence counts over the 23 config repositories unless explicitly marked as workload counts.

| Observation | Count | Meaning |
|---|---:|---|
| Config repositories audited | 23 | complete inventory |
| Private configs | 1 | `skku-alumni-config` |
| Archived configs | 0 | inventory includes archived filter |
| No SCG project repo | 5 | monitoring, cloudflared, office, Renovate, codex-lb |
| Verified SCG project repo(s) | 18 | includes superseded `scg-new-2022-config` |
| Project Dockerfile evidence | all mapped projects | source images exist; not sufficient without publishing |
| Mapped projects with GitHub container workflow | 15 configs / corresponding active image paths | excluding internal-only `ourlim`, `cs-grad-thesis`; superseded source is not usable |
| Legacy nginx Ingress routing | every HTTP config examined | Gateway API migration is universal |
| Clearly multi-image application configs | 9 | ICC grad, S-TOP, attendance, cs-grad, exhibition, ourlim, room, apply, shortener, alumni/timetable also have multi-component shape; see note below |
| Redis present | 2 configs | alumni and timetable; chart non-goal |
| PVC/storage required | codex-lb and monitoring | generic chart cannot represent it |
| Explicit probes | only codex-lb plus cloudflared liveness | generic `/` is not evidence-backed for most apps |
| Explicit replicas >1 | cloudflared (2) | ordinary app replicas are 1 where stated |
| Explicit app resources | PDF, ICC-grad BE, codex-lb, monitoring | preserve only where migration is approved |
| App-level custom route evidence | at least 15 route groups | path splits, aliases, redirects, rewrites, CORS, or source allowlists |
| Observed production host outside `scg.sh` | nearly all app groups | requires ExternalDNS/provider decision |

The “clearly multi-image” count is intentionally not used as a unique registration count: alumni has two FE images from one repo, timetable has Redis, and some configs have two images but each image can be split into a registration. The total evidence-backed ordinary HTTP registrations, if all active and publishable components were approved, is approximately 24: two each for the normal FE/BE applications, three for alumni, and two for timetable, with simple one-image apps added. This is a planning count, not an approval.

### Defaults and deviations

- **Port:** every observed ordinary app component uses 3000, 4000, 8000, 8090, or 8091; none matches the chart default 8080 except timetable BE. `port` is therefore required for almost every registration.
- **Image:** every proposed registration needs `image:` because observed images are `scgskku/*`, `jcy0308/*`, Harbor, or another third-party image rather than derived GHCR. Tags remain workflow-controlled SHA/build tags; do not put `latest`, `prod1`, `qa2`, or SHA tags in metadata.
- **Health:** no ordinary legacy manifest has a readiness/liveness/startup probe except codex-lb. Leave `healthPath` at the chart default only after checking that `GET /` is safe; do not claim a health endpoint from missing probes. Evidence-backed exceptions are ICC lecture `/` (200 fallback, weak health semantics), SCG-SSO `/health/ready` (Keycloak inference), and codex-lb's three explicit health paths in a non-fitting treatment.
- **Replicas:** one is observed for ordinary app workloads; chart defaults suffice. Cloudflared has two but is platform-owned.
- **Resources:** central defaults are appropriate for most; preserve PDF's 2 CPU/3–4 GiB and ICC-grad BE's 1 CPU request only if those apps proceed. Codex/monitoring resources belong in dedicated treatment.
- **Secrets:** `envFromSecrets` is sufficient for one existing Secret on many BE workloads and some FE workloads. Values must be provisioned in each derived namespace before migration.
- **Environment variables:** runtime non-secret env is evidenced for scg-home (`NODE_ENV`, `TZ`) and related components; many frontend values are build-time (`NEXT_PUBLIC_*`) and cannot be supplied by chart runtime `env`. Build-time configuration needs a CI/image contract decision.
- **Routing:** generated route is appropriate only for one host, one Service, root/normal prefix. `route: custom` is evidence-backed for CSE aliases/body/redirect, FE/BE same-host splits, regex rewrites, multiple aliases, CORS policy, `/seminar` redirect, and similar cases.
- **Namespace/storage:** legacy repos often create or select namespaces with names unlike `<app>`/`<app>-staging`; Redis/PVC/emptyDir state must be handled separately. The chart must not copy Namespace, Secret payload, PVC, or legacy Deployment resources.

## 5. Per-application findings

### 5.1 Direct or near-direct generic-chart candidates

#### CSE undergrad GP manage — active

Config `CSE-undergrad-gp-manage-v2-config`, root `kustomization.yaml:1-13`, maps to `SystemConsultantGroup/CSE-undergrad-gp-manage-v2`. `deployment.yaml:15-23` runs `scgskku/cse-undergrad-gp-manage` on container port 8091, one replica, with `envFrom` Secret `cse-undergrad-gp-manage-secret`; the project Dockerfile confirms `PORT=8091`/`EXPOSE 8091`. Service maps 80→8091. Production host is `cssys.cs.skku.ac.kr`; alias `cssys.skku.ac.kr` has no TLS and disables SSL redirect (`ingress.yaml`, `ingress_newdomain.yaml`). Both routes set 2g body size. No probes, resources, commands, security context, RBAC, or volumes.

**Verdict:** one image/Service fits, but use `route: custom` to preserve the two hosts, redirect behavior, and body-size annotation. Health endpoint is unknown. DNS zone and TLS need verification.

#### ICC Haedong seminar reservation — active, simplest representative

`ICC-haedong-seminar-reservation-config/base/deployment.yaml:9,16-23` runs `scgskku/icc-haedong-seminar-reservation`, one replica, port 3000, and imports `icc-haedong-reservation-secret`; Service is 80→3000. Prod overlay `overlays/prod/domain.json` establishes `seminar.scg.skku.ac.kr`; prod tag is pinned to an immutable-looking SHA. No probes/resources/security/commands/volumes/autoscaling. Ingress is one root Prefix route with 200m body limit.

**Verdict:** direct generic-chart fit with `port`, `image`, and `envFromSecrets`. The 200m annotation is not promoted to a platform capability without confirmed upload evidence. Default `/` health remains to be validated.

#### ICC lecture enrollment — active

`ICC-lecture-enrollment-config/base/deployment.yaml` has one replica, `scgskku/icc-lecture-enrollment`, container and Service port 8090, and Secret `icc-lecture-enrollment-secret`; prod host is `profsystem.icc.skku.ac.kr` (`overlays/prod/domain.json`). The project Dockerfile exposes 8090 and starts `node server/app.js`. Secret manifest contains Vault placeholders for application, DB, MinIO, SMTP and session settings; names/mechanism only are retained here. There is no dedicated health route; the application fallback makes `/` return 200 (inference, not a real health check). Dependencies MySQL, MinIO, and SMTP are chart non-goals.

**Verdict:** generic fit with `port`, `image`, and `envFromSecrets`; default `/` is a weak evidence-backed candidate. No staging overlay.

### 5.2 Split applications that need custom routing or separate registration

#### ICC grad dissertation manage — active-ish, prod-only

Config `ICC-grad-dissertation-manage-config` maps to backend and frontend project repos. Prod BE uses `scgskku/icc-grad-dissertation-manage-backend`, port 4000, one replica, `prod-ice-grad-secret`, and a 1 CPU request; FE uses the real image name `scgskku/ice-gs-thesis-fe-prod` (the `ice-gs` typo is present in workflow and config), port 3000. Both Ingresses use `grad.icc.skku.ac.kr`; BE is `/v1`, FE `/`; BE body limit is 200m. Namespace is `ice-gs-thesis-prod`; no Namespace object is in git. No probes; external Kafka, MinIO, and DB are secret-backed dependencies.

The config is prod-only. FE workflow checks out the old config name (GitHub redirect currently masks stale documentation) and its `qa.yml` targets missing `overlays/qa/fe`, so QA config update is broken/stale evidence.

**Verdict:** two registrations are the smallest application treatment, with a custom route set for the same-host `/` + `/v1` split. Confirm BE port and external dependencies before migration. Preserve the image-name typo as an image override, not in repository identity.

#### S-TOP — active-ish, prod + QA

`S-TOP-config` maps to `S-top-backend` and `S-top-frontend`. Prod host is `s-top.cs.skku.edu`; QA host is `stop.scg.skku.ac.kr`, in namespaces `s-top-prod` and `s-top-qa`. Prod images are `jcy0308/stop-be-prod` (port 8000, Secret `stop-secret`) and `scgskku/stop-fe-prod` (port 3000). QA images are `*-qa`; QA is develop-branch based, not the platform's PR-preview model. FE uses `/`; BE uses `/v1(/|$)(.*)` with nginx rewrite `/$2` and 200m body size. FE has five build-time `NEXT_PUBLIC_*` values.

**Verdict:** two registrations, both with explicit images/ports; custom route for same-host path split and rewrite. QA is evidence for a staging-like environment but promotion semantics must be decided. `cs.skku.edu` and `scg.skku.ac.kr` require DNS provider support.

#### attendance checker — active

`attendance-checker-config` maps to FE and BE. FE uses `scgskku/attendance-checker-fe-dev`, port 3000, one replica, root route at `attendance.scg.skku.ac.kr`; no env/probes. BE uses `scgskku/attendance-checker-be-dev`, declares port 8000, imports `attendance-checker-be-secret`, but Service maps 80→8080 (`base/be/service.yaml:6-11`). BE prod/overlay route is `api.attendance.scg.skku.ac.kr`, `/v1/(.*)`, ImplementationSpecific, with CORS. Dockerfile has no EXPOSE and CMD is a placeholder loop.

**Verdict:** FE is a generated-route candidate. BE needs custom route and is blocked on verifying the actual listener and fixing the 8000-versus-8080 mismatch before migration. Do not silently normalize the port.

#### exhibition — active

`exhibition-config` maps to FE/BE. FE port 3000 and BE declared 8000; BE Service targets 8080, while the BE Dockerfile exposes 8080, strongly indicating the Deployment declaration is stale/wrong. FE production has seven TLS/host aliases, with canonical likely `exhibition.scg.sh`; BE canonical is `api.exhibition.scg.sh`, `/v1` with rewrite/CORS. FE aliases include `swgp.exhibition.scg.sh`, `exhibition.scg.skku.ac.kr`, `scg.exhibition.scg.sh`, `exhibition2.scg.skku.ac.kr`, `swgp.exhb.scg.skku.ac.kr`, and `aiswm.exhb.scg.skku.ac.kr`. No probes/resources/security/commands/RBAC/volumes.

**Verdict:** two registrations. FE and BE require custom routes; validate all aliases, DNS, CORS and Gateway API regex/rewrite equivalence. Resolve the BE port declaration explicitly; do not copy the erroneous declaration.

#### room reservation — active

`room-reservation-config` maps to FE/BE. FE is port 3000 with `reservation-fe-secret`; BE is port 8000 with `reservation-secret`; both one replica and Service target matching ports. Production domains are `semi.room.scg.skku.ac.kr` and `api.reservation.scg.skku.ac.kr`; dev domains are `reservation-dev.scg.skku.ac.kr` and `api.reservation-dev.scg.skku.ac.kr`. Legacy base Ingresses use regex `/(.*)`, rewrite `/$1`, CORS and placeholders; production paths are root.

**Verdict:** separate registrations. FE may use generated routing; BE requires custom route for rewrite/CORS. The platform-derived `staging.<domain>` does not match legacy `*-dev`; DNS/product acceptance is required before calling dev staging.

#### scg-apply — active-ish

`scg-apply-config` maps to FE/BE. Prod host is `apply.scg.skku.ac.kr`; FE is port 3000 and BE port 8000, both one replica; BE imports `scg-apply-secret`. Prod images are `scgskku/scg-apply-fe-prod` and `scgskku/scg-apply-be-prod`; dev overlay uses internal Harbor `:dev0` images without a verifiable GitHub publisher. Prod uses `/` and `/v1`, body size 200m; base Services are NodePort and prod patches them. BE workflow passes `BUILD_DATABASE_URL` as a build argument, so it is build-time secret/config evidence, not chart runtime `env`.

**Verdict:** two registrations with custom same-host `/` + `/v1` routes, explicit prod image/ports and BE Secret. Dev image promotion is unverifiable; stale feature branches should not be treated as environments.

#### shortener — active

`shortener-config` maps to FE/API. FE uses `scgskku/shortener-fe-prod`, port 3000, host `app.scg.sh`, root route. API uses `scgskku/shortener-api-prod`, port 8000, `shortener-secret`; prod hosts are `api.scg.sh` and `scg.sh`, with regex `/(.*)`, rewrite `/$1`, and CORS for FE/QA. QA patches use `api.shortener-qa.scg.skku.ac.kr` and `shortener-qa.scg.skku.ac.kr` (FE has analogous patch).

**Verdict:** FE generated route; API custom route preserving both production aliases, rewrite and CORS only after Gateway validation. Separate registrations. QA hostname does not equal derived staging hostname.

#### alumni — active/private, three registrations plus Redis dependency

`skku-alumni-config` is private and current (main 2026-08-07), with a `chore/backend-cicd` branch needing comparison. The frontend project is a monorepo producing two images: `scgskku/alumni-user-fe-prod` and `scgskku/alumni-admin-fe-prod`; backend image is `scgskku/alumni-be-prod`. Prod hosts are `alumni.scg.skku.ac.kr`, `admin.alumni.scg.skku.ac.kr`, and `api.alumni.scg.skku.ac.kr`; dev hosts are `test.alumni...`, `test.admin.alumni...`, and `api.test.alumni...`. BE imports `alumni-be-secret` and has CORS for both FE hosts. Per-overlay FE Secrets are `alumni-user-fe-secret` and `alumni-admin-fe-secret`. Each FE owns a host; admin has regex/rewrite annotations. Redis is `redis:7-alpine` with `emptyDir` and `--appendonly yes`, so restart loses data.

**Verdict:** three registrations (user FE, admin FE, BE), each explicit image/port; generated routes are plausible for the host-separated FEs, while admin rewrite and BE CORS need Gateway validation/custom treatment. Redis is outside chart v1 and must be platform/separately managed. Private-repository PR preview access needs an org-wide GitHub App permission decision.

#### timetable planner — active, two registrations plus Redis dependency

`timetable-planner-config` maps to FE/BE. FE is `scgskku/timetable-planner-fe-prod`, port 3000, host `skkedule.scg.skku.ac.kr`; BE is `scgskku/timetable-planner-be-prod`, port 8080, host `api.skkedule.scg.skku.ac.kr`, and imports `timetable-planner-be-secret`. Both are one replica with no probes/resources/security/commands. Dev hosts use `skkedule-dev...` and `api.skkedule-dev...`. Redis is `redis:7-alpine`, password-backed by `timetable-planner-redis-secret`, with persistence disabled.

**Verdict:** two generated-route registrations are plausible because each owns one host and root path. Redis is outside chart v1. Dev `-dev` naming conflicts with derived `staging.` and requires a product/DNS decision.

### 5.3 Single app with missing or conditional evidence

#### PDF converter — stale/blocked

`PDF-config/base/deployment.yaml:15-30` runs `jcy0308/pdf-module`, port 4000, one replica, Secret `pdf-secret`, and explicit requests/limits of CPU 2 / memory 3Gi and CPU 2 / memory 4Gi. The only `dev` overlay uses shared namespace `kafka`; Service is 80→4000. No Ingress, HTTPRoute, or domain exists in the tree or rendered output. Last config evidence is 2025-01-27.

**Verdict:** no valid generic-chart metadata: the required domain is absent and the chart always generates an HTTPRoute and derives a per-app namespace. Confirm active status, intended domain/route, shared `kafka` ownership, and whether it is an HTTP app. Do not invent metadata.

#### SCG SSO / Keycloak — platform candidate, not approved application

`SCG-SSO-config` deploys `scgskku/scg-sso`, one replica, port 8080, Secret `scg-sso-secret`, and host `sso.scg.skku.ac.kr`. The project Dockerfile uses `keycloak:latest`, enables health/metrics, and starts optimized Keycloak; inferred readiness is `/health/ready`. The Secret contains DB and bootstrap-admin settings (names/mechanism only). Ingress has root redirect annotation to `/realms/inhouse/account`. External MySQL and identity state are central to operation.

**Verdict:** classify as platform identity infrastructure unless an explicit exception is approved. A conditional app draft would require `port: 8080`, `healthPath: /health/ready`, `envFromSecrets`, and custom root redirect, but generic chart v1 excludes databases/state treatment. Workflow also has a typo'd Docker registry secret name; Keycloak base image is unpinned `latest`.

#### cs-grad thesis — stale/non-fitting

`cs-grad-thesis-config` has FE/BE for prod, QA and dev: QA uses namespace `cs-grad-thesis-qa`, while prod and dev use `cs-grad-thesis`; prod host `cssys.scg.skku.ac.kr` splits FE `/` and BE `/v1`. FE/BE use internal `registry.scg.skku.ac.kr` images, ports 3000/8000, NodePort Services, and BE references external ConfigMap `cs-grad-thesis-prod-config` that is not defined in any fetched branch. Project repos default to `develop`, have Dockerfiles but no GitHub workflows; tags are manually managed (`prod0`, `prod2`, etc.). Config last changed 2024-02-11 and all branches are stale.

**Verdict:** do not register until image publication/provenance and ConfigMap provisioning are resolved. If revived, use separate FE/BE registrations plus custom route for same-host path split. Dev FE TLS name is inconsistently `cs-grad-thesis-prod-tls`.

#### ourlim — stale/non-fitting pending image and route decisions

`ourlim-config` has independent FE/BE deployments, port 3000/8000, one replica, NodePort Services and prod host `ourlim.scg.skku.ac.kr`; BE imports `ourlim-secret`; BE path is `/api/v1`, FE `/`. Images are internal Harbor `prod2`/`prod1`; project has backend/frontend Dockerfiles but no GitHub workflow. Two registrations would need the same domain, custom routes, and a policy permitting one project repo to back two registrations; image promotion is not attested.

**Verdict:** no generic metadata approval until registry/publishing and same-host route ownership are decided. A future FE/BE split is the smallest treatment; do not add a speculative multi-component framework.

#### scg-home — current but overlay evidence is broken

`scg-home-config` maps FE to `SystemConsultantGroup/scg-2026-frontend` and BE to `SystemConsultantGroup/SCG-new-2022` by workflow/image evidence. Base images are `scgskku/scg-home-fe-prod` (port 3000) and `scgskku/scg-home-be-prod` (port 8000); runtime env includes `NODE_ENV=production`, `TZ=Asia/Seoul`. FE host is `scg.skku.ac.kr` and includes a `/seminar` 308 redirect to `seminar.scg.skku.ac.kr`; BE host is `be.scg.skku.ac.kr`, with `/api/v2`, CORS, and Prometheus annotations. Prod FE and BE overlays fail for duplicate resource/patch target defects and image selector drift toward Harbor.

**Verdict:** separate registrations using workflow-backed Docker Hub images, but validate/repair route and image promotion decisions first. FE requires custom route for `/seminar`; BE needs `routePath: /api/v2` only if central CORS behavior is sufficient, otherwise custom route. Do not register `scg-new-2022-config` separately; it is superseded.

#### codex-lb — third-party dedicated treatment

`codex-lb-config` uses `ghcr.io/soju06/codex-lb:1.22.0`, one Recreate replica due SQLite/RWO, a 5Gi RWO PVC, writable tmp/cache `emptyDir`, custom command on port 2455, explicit non-secret env, 200m/256Mi requests and 1 CPU/1Gi limits, and startup/readiness/liveness paths `/health/startup`, `/health/ready`, `/health/live`. Ingress host is `dev.codex-lb.scg.sh` with source allowlist, HTTP/1.1, buffering and timeout annotations.

**Verdict:** no SCG application registration. Use platform-owned/dedicated chart or a narrow codex-lb extension; generic chart cannot safely represent persistence, command, lifecycle, hardening, probes, and ingress policy. No production domain is evidenced.

### 5.4 Platform and superseded repositories

- **SCG-Monitoring-Config:** kube-prometheus-stack with Grafana/Alertmanager PVCs, RBAC and cluster monitoring. Keep under `argocd/platform`; fix and validate the singular/plural values filename reference before sync. Do not create `meta.yaml`.
- **cloudflared-config:** two-replica outbound Cloudflare tunnel, no Service/Ingress, liveness `/ready:2000`; at HEAD `d22f351`, `kustomization.yaml` includes `deployment.yaml`, `namespace.yaml`, and `secret.yaml`, and the kustomization renders cleanly. Platform-owned; no registration.
- **office-config:** one-replica `nginx:alpine` LoadBalancer 10443 SSL stub for `office.scg.sh`, ConfigMap-mounted nginx config returning 200; no backend or certificate material is evidenced. Platform probe component or delete with owner approval; no registration.
- **renovate-config:** Tuesday CronJob using Renovate, Secret and ConfigMap; no HTTP Service. Platform tool; no registration.
- **scg-new-2022-config:** stale/superseded homepage source. Base has cluster-local `scg-be:1`/`scg-fe:1`, duplicate/hostless ingress, a missing `scg-be-v2-svc` reference, and messy overlay accumulation. Its project workflow now publishes BE to `scg-home-config`. Do not double-register. The project frontend Dockerfile contains an inline GitLab credential (value intentionally omitted); rotate it and audit history.

## 6. Environment, routing, and domain compatibility

### Environment model

Legacy production is usually an explicit overlay/namespace, but names do not match the proposal's `<app>`, `<app>-staging`, and `<app>-preview-N`. QA/dev are variously `qa`, `dev`, `*-qa`, `*-dev`, `test.*`, or `staging`-like only by intent. In particular:

- S-TOP QA is develop-branch based and uses `stop.scg.skku.ac.kr` plus QA images.
- Room reservation uses `*-dev`; shortener uses `*-qa`; alumni uses `test.*`; timetable uses `*-dev`; scg-apply uses `dev.apply...` and internal `:dev0` images.
- ICC grad, ICC lecture, ICC Haedong and SSO have prod-only evidence.
- cs-grad uses `cs-grad-thesis-qa` for QA and `cs-grad-thesis` for prod/dev, rather than separate derived namespaces.

These are migration/product decisions, not reasons to encode environment names or image tags in `meta.yaml`. Staging promotion semantics, Secret provisioning, and image availability must be proven before generating staging/preview Applications.

### Routing

The generated route is sufficient only where one registration owns one host, one Service, and a normal root prefix. It is plausible for ICC Haedong, ICC lecture, attendance FE, room FE, shortener FE, timetable FE/BE, and alumni's host-separated FEs (subject to annotation validation). It is not sufficient for:

- CSE aliases plus body-size and redirect behavior;
- ICC grad, S-TOP, scg-apply, cs-grad, and ourlim same-host FE/BE path splits;
- attendance, exhibition, room, and shortener API regex/rewrite/CORS behavior;
- exhibition's seven FE aliases;
- scg-home's `/seminar` 308 redirect and likely BE CORS/path policy;
- SCG-SSO's app-root redirect;
- codex-lb's source allowlist/timeouts and non-generic workload.

Use `route: custom` only for these evidence-backed cases. Custom route sources must remain within the chart's intended Gateway API route allowlist; they must not copy legacy Ingress, Deployment, Certificate, Namespace, or Secret resources. Gateway API regex/rewrite and CORS equivalence must be validated with rendered schemas and traffic tests.

### DNS and TLS

Observed canonical domains span `scg.sh`, `scg.skku.ac.kr`, `cs.skku.edu`, `cs.skku.ac.kr`, and `icc.skku.ac.kr`. The design currently filters ExternalDNS to `scg.sh`; provider/domain-filter support for the other zones is required. Existing cert-manager annotations/TLS secrets demonstrate intended HTTPS but do not prove the certificate is issued or DNS is correct. The proposed ListenerSet wildcard certificate does **not** justify a wildcard DNS record; ExternalDNS must create explicit apex, staging, and preview records from HTTPRoutes.

## 7. Proposed metadata drafts

These are proposed shapes, not files. They contain only schema fields supported by the design and evidence-backed deviations. Tags are intentionally absent. `route: custom` means a separately validated `routes/` directory is required.

### Ready/near-ready registrations

```yaml
# applications/cse-undergrad-gp-manage/meta.yaml
repository: SystemConsultantGroup/CSE-undergrad-gp-manage-v2
domain: cssys.cs.skku.ac.kr
image: scgskku/cse-undergrad-gp-manage
port: 8091
envFromSecrets:
  - cse-undergrad-gp-manage-secret
route: custom

# applications/icc-haedong-seminar-reservation/meta.yaml
repository: SystemConsultantGroup/ICC-haedong-seminar-reservation
domain: seminar.scg.skku.ac.kr
image: scgskku/icc-haedong-seminar-reservation
port: 3000
envFromSecrets:
  - icc-haedong-reservation-secret

# applications/icc-lecture-enrollment/meta.yaml
repository: SystemConsultantGroup/ICC-lecture-enrollment
domain: profsystem.icc.skku.ac.kr
image: scgskku/icc-lecture-enrollment
port: 8090
healthPath: /
envFromSecrets:
  - icc-lecture-enrollment-secret
```

`healthPath: /` for lecture enrollment is a weak inference from the app fallback, not a dedicated health endpoint. Validate before relying on readiness.

### Split registrations

```yaml
# applications/icc-grad-dissertation-backend/meta.yaml
repository: SystemConsultantGroup/ICC-grad-dissertation-manage-backend
domain: grad.icc.skku.ac.kr
image: scgskku/icc-grad-dissertation-manage-backend
port: 4000
envFromSecrets:
  - prod-ice-grad-secret
route: custom

# applications/icc-grad-dissertation-frontend/meta.yaml
repository: SystemConsultantGroup/ICC-grad-dissertation-manage-frontend
domain: grad.icc.skku.ac.kr
image: scgskku/ice-gs-thesis-fe-prod
port: 3000
route: custom

# applications/s-top-backend/meta.yaml
repository: SystemConsultantGroup/S-top-backend
domain: s-top.cs.skku.edu
image: jcy0308/stop-be-prod
port: 8000
envFromSecrets:
  - stop-secret
route: custom

# applications/s-top-frontend/meta.yaml
repository: SystemConsultantGroup/S-top-frontend
domain: s-top.cs.skku.edu
image: scgskku/stop-fe-prod
port: 3000
route: custom

# applications/attendance-checker-frontend/meta.yaml
repository: SystemConsultantGroup/attendance-checker-frontend
domain: attendance.scg.skku.ac.kr
image: scgskku/attendance-checker-fe-dev
port: 3000

# applications/attendance-checker-backend/meta.yaml
repository: SystemConsultantGroup/attendance-checker-backend
domain: api.attendance.scg.skku.ac.kr
image: scgskku/attendance-checker-be-dev
port: 8000
envFromSecrets:
  - attendance-checker-be-secret
route: custom

# applications/exhibition-frontend/meta.yaml
repository: SystemConsultantGroup/exhibition-frontend
domain: exhibition.scg.sh
image: scgskku/exhibition-fe
port: 3000
route: custom

# applications/exhibition-backend/meta.yaml
repository: SystemConsultantGroup/exhibition-backend
domain: api.exhibition.scg.sh
image: scgskku/exhibition-be
port: 8000
envFromSecrets:
  - exhibition-be-secret
route: custom

# applications/room-reservation-frontend/meta.yaml
repository: SystemConsultantGroup/room-reservation-frontend
domain: semi.room.scg.skku.ac.kr
image: scgskku/reservation-fe-prod
port: 3000
envFromSecrets:
  - reservation-fe-secret

# applications/room-reservation-backend/meta.yaml
repository: SystemConsultantGroup/room-reservation-backend
domain: api.reservation.scg.skku.ac.kr
image: scgskku/reservation-be-prod
port: 8000
envFromSecrets:
  - reservation-secret
route: custom

# applications/scg-apply-frontend/meta.yaml
repository: SystemConsultantGroup/scg-apply-frontend
domain: apply.scg.skku.ac.kr
image: scgskku/scg-apply-fe-prod
port: 3000
route: custom

# applications/scg-apply-backend/meta.yaml
repository: SystemConsultantGroup/scg-apply-backend
domain: apply.scg.skku.ac.kr
image: scgskku/scg-apply-be-prod
port: 8000
envFromSecrets:
  - scg-apply-secret
route: custom

# applications/shortener-frontend/meta.yaml
repository: SystemConsultantGroup/scg-url-shortener-frontend
domain: app.scg.sh
image: scgskku/shortener-fe-prod
port: 3000

# applications/shortener-api/meta.yaml
repository: SystemConsultantGroup/scg-url-shortener-backend
domain: api.scg.sh
image: scgskku/shortener-api-prod
port: 8000
envFromSecrets:
  - shortener-secret
route: custom

# applications/skku-alumni-user-frontend/meta.yaml
repository: SystemConsultantGroup/skku-alumni-frontend
domain: alumni.scg.skku.ac.kr
image: scgskku/alumni-user-fe-prod
port: 3000

# applications/skku-alumni-admin-frontend/meta.yaml
repository: SystemConsultantGroup/skku-alumni-frontend
domain: admin.alumni.scg.skku.ac.kr
image: scgskku/alumni-admin-fe-prod
port: 3000
# custom route is conditional on proving the legacy regex/rewrite is required

# applications/skku-alumni-backend/meta.yaml
repository: SystemConsultantGroup/skku-alumni-backend
domain: api.alumni.scg.skku.ac.kr
image: scgskku/alumni-be-prod
port: 8000
envFromSecrets:
  - alumni-be-secret
route: custom

# applications/timetable-planner-frontend/meta.yaml
repository: SystemConsultantGroup/timetable-planner-frontend
domain: skkedule.scg.skku.ac.kr
image: scgskku/timetable-planner-fe-prod
port: 3000

# applications/timetable-planner-backend/meta.yaml
repository: SystemConsultantGroup/timetable-planner-backend
domain: api.skkedule.scg.skku.ac.kr
image: scgskku/timetable-planner-be-prod
port: 8080
envFromSecrets:
  - timetable-planner-be-secret
```

The alumni BE `route: custom` draft is conservative because CORS is explicit in legacy annotations; remove it only after central Gateway CORS support is demonstrated. Likewise, attendance/exhibition/room/shortener custom routes preserve observed regex, rewrites, aliases and CORS; their exact Gateway API form is not yet validated.

### Blocked or conditional drafts (not ready to create)

- **PDF:** no draft because `domain` and HTTP route are absent; confirm active status and intended namespace/route first. If approved later, evidence supports `image: jcy0308/pdf-module`, `port: 4000`, resources 2 CPU/3–4 GiB, and `envFromSecrets: [pdf-secret]`, but the current chart cannot express route-disabled/shared `kafka` namespace.
- **SCG-SSO:** do not create an application registration until identity-provider ownership and DB/state treatment are approved. Conditional values are `repository: SystemConsultantGroup/SCG-SSO`, `domain: sso.scg.skku.ac.kr`, `image: scgskku/scg-sso`, `port: 8080`, `healthPath: /health/ready`, `envFromSecrets: [scg-sso-secret]`, `route: custom`.
- **cs-grad thesis:** do not create until internal image publication and external ConfigMap `cs-grad-thesis-prod-config` are resolved. Future registrations would be FE `SystemConsultantGroup/cs-grad-thesis-frontend`, port 3000 and BE `SystemConsultantGroup/cs-grad-thesis-backend`, port 8000, both with internal image overrides and custom routes.
- **ourlim:** do not create until internal Harbor publication and same-domain FE/BE route ownership are approved. Future registrations would use `SystemConsultantGroup/ourlim` twice, `ourlim.scg.skku.ac.kr`, ports 3000/8000, BE `envFromSecrets: [ourlim-secret]`, and custom routes.
- **scg-home:** the two drafts above are evidence-backed but gated on fixing the broken prod overlays and choosing the canonical BE path/CORS policy. FE uses `SystemConsultantGroup/scg-2026-frontend`, `scg.skku.ac.kr`, `scgskku/scg-home-fe-prod`, port 3000, `route: custom`; BE uses `SystemConsultantGroup/SCG-new-2022`, `be.scg.skku.ac.kr`, `scgskku/scg-home-be-prod`, port 8000, `routePath: /api/v2`, and `env` `{NODE_ENV: production, TZ: Asia/Seoul}` pending route validation.

No metadata is proposed for monitoring, cloudflared, office, Renovate, codex-lb, Redis, or superseded `scg-new-2022-config`.

## 8. Ranked minimum chart/platform capabilities

1. **Executable metadata schema and validator.** Reject unknown fields, absent full repository IDs/domains, and invalid `route`/resource shapes before migration.
2. **Safe generated one-image chart.** Deployment, Service, HTTPRoute, readiness, central resources/security defaults, managed namespaces and PSA labels; keep tags automated.
3. **Custom Gateway API route source.** Validate a narrow allowlist and environment hostname/parent injection for path splits, aliases, rewrites, redirects and CORS. Do not expose arbitrary Kubernetes resources.
4. **External secret provisioning contract.** Ensure named Secrets exist in `<app>`, staging and preview namespaces without copying legacy payloads.
5. **Multi-zone DNS/TLS support.** Configure provider/domain filters for `scg.sh`, `scg.skku.ac.kr`, `cs.skku.edu`, `cs.skku.ac.kr`, and `icc.skku.ac.kr`; validate explicit records and ListenerSet certificates.
6. **Image publication/promotion contract.** Establish immutable SHA/digest publication for Docker Hub/internal-image exceptions or GHCR migration, and define QA/dev-to-staging promotion. Build-time frontend environment must be supplied by CI, not assumed to be chart runtime `env`.
7. **Separate registration policy.** Permit FE/BE split registrations, including documented same-repository multiple registrations, while preventing hostname collisions and unintended ListenerSet ownership.
8. **Narrow dedicated treatments.** Only after evidence: persistence/custom command for codex-lb; platform charts for Redis, SSO, monitoring, cloudflared, Renovate and office. Do not generalize these into the application chart.

## 9. Outliers and unresolved decisions

1. Confirm active production for stale PDF, cs-grad thesis, SSO, ourlim, and ICC grad evidence before migration.
2. Resolve attendance BE Service target 8080 versus declared/listener evidence 8000.
3. Resolve exhibition BE declared 8000 versus Dockerfile/Service evidence 8080.
4. Resolve PDF's intended domain, route-disabled behavior, shared `kafka` namespace, and resource preservation.
5. Fix or retire the monitoring values filename mismatch.
6. Investigate office's missing certificate/listener for 10443 before treating it as a platform probe.
7. Repair scg-home overlay duplicate resource, patch-name mismatch, and stale Harbor image selectors; scg-new-2022 prod BE and FE also have patch target mismatches while the base renders; do not double-register superseded scg-new-2022.
8. Rotate the inline GitLab credential found in `SCG-new-2022/frontend/Dockerfile`; no value is reproduced here.
9. Resolve whether Redis should be externally provisioned, separately charted, or replaced; current alumni Redis loses data on restart and timetable Redis has persistence disabled.
10. Verify Gateway API behavior for nginx regex/rewrite, CORS, source ranges, aliases, redirects, body sizes, and timeouts.
11. Provision and verify all named Secrets in derived namespaces. Vault placeholder integration is not pinned to one mechanism by repository evidence.
12. Decide whether `*-dev`, `*-qa`, `test.*`, and S-TOP QA map to staging or remain separate product environments.
13. Verify application health endpoints. Do not infer `/` readiness merely because no legacy probe exists.
14. Confirm private-repository GitHub App access for alumni PR previews and all private project repositories.
15. Confirm no Argo live state is hidden outside the checked-in central repos; this audit cannot attest cluster deployment.

## 10. Migration order

1. **ICC Haedong seminar reservation:** simplest one image/one Service/root route; validate chart, namespace, Secret, Gateway and DNS.
2. **ICC lecture enrollment:** same shape with port 8090 and external MySQL/MinIO/SMTP dependency checks.
3. **CSE undergrad GP manage:** validate custom two-host route and 2g/redirect behavior.
4. **Simple split components:** attendance FE, room FE, shortener FE, timetable FE/BE, then validate separate registrations and staging promotion.
5. **Custom split applications:** attendance BE, exhibition, room BE, shortener API, S-TOP, scg-apply, and ICC grad; migrate only after route conformance and concrete port checks.
6. **Alumni:** validate three registrations, private-repository access, CORS, FE build-time configuration and Redis ownership.
7. **scg-home:** repair/render overlays and decide redirect/CORS/path ownership before migration.
8. **Conditional stale apps:** reassess PDF, cs-grad and ourlim only after active status, image publishing, ConfigMap/Secret and DNS decisions.
9. **Platform work:** separately migrate/fix monitoring, cloudflared, office, Renovate, codex-lb, SSO and Redis; none should be forced through the generic app chart.

## 11. Proposed later changes to `APPLICATION_PLATFORM.md`

These are recommendations, not edits made by this audit:

- Document a first-class multi-registration/same-repository rule and hostname-collision validation.
- Add an evidence-gated route capability matrix covering Gateway API path prefix, regex/rewrite, redirect, CORS, aliases, source allowlists, body limits and timeout behavior.
- Define image overrides for non-GHCR images and a publish-attestation/promotion rule for Docker Hub and internal registries.
- Add multi-zone ExternalDNS/provider configuration requirements and explicitly distinguish wildcard certificate SANs from DNS records.
- Clarify how legacy `dev`/`qa`/`test` environments map (or do not map) to `staging` and previews.
- Define external Secret provisioning and build-time frontend environment contracts.
- Add a decision record for platform-owned stateful/third-party components (Redis, SSO, monitoring, cloudflared, codex-lb, Renovate, office).
- Require application-level health verification before setting `healthPath`; absence of a legacy probe is not proof that `/` is safe.
- Add a migration gate requiring `kubectl kustomize`/Gateway schema validation and a live smoke test for every custom route.

## Acceptance report

```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "Updated exactly /home/scg/kubernetes/legacy-config-sweep-report.md; no source, project, platform, or other files were edited."
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "Report covers all 23 inventory records, four lane handoffs, mappings, workload evidence, fit verdicts, metadata drafts, blockers, limitations, migration order, and proposed platform changes."
    }
  ],
  "changedFiles": [
    "/home/scg/kubernetes/legacy-config-sweep-report.md"
  ],
  "testsAddedOrUpdated": [],
  "commandsRun": [
    {
      "command": "read report and cited snapshots under /tmp/scg-legacy-sweep-6XxutiDo",
      "result": "passed",
      "summary": "Reviewed the report plus cloudflared, office, scg-new-2022, and cs-grad-thesis snapshots."
    },
    {
      "command": "kubectl kustomize /tmp/scg-legacy-sweep-6XxutiDo/scan-1/repos/cloudflared-config; kubectl kustomize /tmp/scg-legacy-sweep-6XxutiDo/scan-3/repos/scg-new-2022-config/base/{be,fe}",
      "result": "passed",
      "summary": "Cloudflared and scg-new-2022 base BE/FE rendered cleanly."
    },
    {
      "command": "expected-failure check for scg-new-2022-config/overlays/prod/{be,fe} patch targets",
      "result": "passed",
      "summary": "Both prod overlays failed as expected for be-ingress/fe-ingress patch-target mismatches."
    },
    {
      "command": "grep -nE 'cloudflared-config|scg-new-2022-config prod|QA uses namespace|cs-grad uses|office-config' legacy-config-sweep-report.md",
      "result": "passed",
      "summary": "Reviewed all correction-related occurrences and confirmed they are internally consistent."
    },
    {
      "command": "git status --short -- legacy-config-sweep-report.md",
      "result": "passed",
      "summary": "Only the requested report is untracked; no staged files."
    },
    {
      "command": "python3 JSON parse of the acceptance-report fenced block",
      "result": "passed",
      "summary": "Acceptance JSON parses and criterion-1 is satisfied."
    }
  ],
  "validationOutput": [
    "All render outcomes and repository-level evidence reported here are the validation results recorded by the four supplied lane handoffs.",
    "No secret values or inline credential values are present in this report."
  ],
  "residualRisks": [
    "Live cluster/Argo state was not available.",
    "Expected scan-N files were absent from the filesystem; supplied handoff texts were used instead.",
    "DNS, Secret provisioning, image promotion, health endpoints, and Gateway API route equivalence remain unverified.",
    "Several applications are stale, broken, superseded, or require dedicated platform treatment."
  ],
  "noStagedFiles": true,
  "diffSummary": "Corrected cloudflared wiring/render status, scg-new-2022 render baseline, office volume-mount interpretation, and cs-grad-thesis namespaces.",
  "reviewFindings": [
    "no blockers in the report artifact; migration blockers are explicitly listed as residual findings"
  ],
  "manualNotes": "Changed sections: 3, 5.3, 5.4, 6, and 9. All four listed corrections are resolved in this report; no secret values are included."
}
```
