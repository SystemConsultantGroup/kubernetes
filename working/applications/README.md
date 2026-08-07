# working/applications — paper port (schema pressure-testing)

**Status: non-authoritative.** This tree pressure-tests the strict registry contract in
`working/APPLICATION_PLATFORM.md` against the 23 legacy `SystemConsultantGroup/*-config`
repositories. Each `PORTING.md` pins its legacy config repo to the 2026-08-07 snapshot
commit; excluded repositories and components are recorded in [`EXCLUDED.md`](EXCLUDED.md).
This is snapshot-only repository evidence; no live cluster or Argo CD state was observed.
Nothing here is operational:

- **No `lock.yaml` anywhere.** No usable attested digest was available from the legacy evidence. Lock files are created only by the central lock writer once the §7 reusable workflow is live.
- **No chart, no rendering, no sync.** The generic application chart, strict schema
  validators, ListenerSets, and the ApplicationSet generator do not exist yet
  (spec §13/§14 proofs pending).
- **No custom-route migration.** Three applications carry `routes/` HTTPRoute drafts below; they are gated on the §5.6/§13.11 Kustomize-injection and allowlist proof.

Files move verbatim to the registry root `applications/<application>/` (spec §3) only
when the platform is implemented and the per-application blockers are cleared.

## Layout

```
working/applications/
  README.md                     this file
  <application>/meta.yaml       strict-schema intent draft when required facts are known
  <application>/PORTING.md      assumptions, blockers, unsupported legacy behavior
  <application>/routes/         constrained Gateway API HTTPRoute sources, only when routes: custom
```

Assumptions, evidence pointers, and unresolved questions are tracked in each
application's `PORTING.md` (not in `meta.yaml`, which is machine-validated intent).

## Disposition table (all 23 reviewed config repos)

Config repo names link to the 2026-08-07 snapshot commit; excluded rows link to
[`EXCLUDED.md`](EXCLUDED.md) for classification, defects, and pinned evidence.

| Legacy config repo (pinned snapshot) | Verdict | Disposition | Created under `working/applications/` |
| --- | --- | --- | --- |
| [`attendance-checker-config`](https://github.com/SystemConsultantGroup/attendance-checker-config/tree/6a9f6e78c740bac6706990d7d98b203382868dee) | ordinary + blocked BE | FE draft; BE notes only pending a runnable image/listener | `attendance-checker-frontend`, `attendance-checker-backend` |
| [`cloudflared-config`](https://github.com/SystemConsultantGroup/cloudflared-config/tree/d22f35190c3c5a91e2b041e8a28113fc2695025f) | platform | excluded — outbound Cloudflare tunnel, no SCG source repo → [EXCLUDED.md](EXCLUDED.md) | — |
| [`codex-lb-config`](https://github.com/SystemConsultantGroup/codex-lb-config/tree/aea6b04006b0c4e304b4f3f0aa2e3aed1b5bf928) | platform/stateful/3rd-party | excluded — PVC-backed SQLite, custom command, dev-only host, no SCG repo → [EXCLUDED.md](EXCLUDED.md) | — |
| [`CSE-undergrad-gp-manage-v2-config`](https://github.com/SystemConsultantGroup/CSE-undergrad-gp-manage-v2-config/tree/44fa5e43af1dfc671a905b890fb9236c1a0ac605) | ordinary | 1 app (multi-domain, generated routes) | `cse-undergrad-gp-manage` |
| [`cs-grad-thesis-config`](https://github.com/SystemConsultantGroup/cs-grad-thesis-config/tree/9e27ac372a01746a9d60154452c8308b9ae69abf) | stale/superseded | excluded — dormant 2024, no trusted publisher, external ConfigMap config → [EXCLUDED.md](EXCLUDED.md) | — |
| [`exhibition-config`](https://github.com/SystemConsultantGroup/exhibition-config/tree/a0b7ead72f7e2a777d7d2b9474ce4e3b669d8cf0) | ordinary | 2 apps (host-separated) | `exhibition-frontend`, `exhibition-backend` (custom) |
| [`ICC-grad-dissertation-manage-config`](https://github.com/SystemConsultantGroup/ICC-grad-dissertation-manage-config/tree/d5f320b702f6600fdc22de3a980c0c3c0c0beb35) | ordinary | 1 app (same-host FE/BE, generated routes) | `icc-grad-dissertation-manage` |
| [`ICC-haedong-seminar-reservation-config`](https://github.com/SystemConsultantGroup/ICC-haedong-seminar-reservation-config/tree/58e4f2e22fbecf4fcc2001b4ad885320d22fbd52) | ordinary | 1 app | `icc-haedong-seminar-reservation` |
| [`ICC-lecture-enrollment-config`](https://github.com/SystemConsultantGroup/ICC-lecture-enrollment-config/tree/c851b8607c426327aea2ac847fd421a38b8496e1) | ordinary | 1 app | `icc-lecture-enrollment` |
| [`office-config`](https://github.com/SystemConsultantGroup/office-config/tree/aeed8ed38dfabd38c436ca527bdf1e0679aae86e) | platform | excluded — nginx static stub, LoadBalancer, in-pod TLS, no project repo → [EXCLUDED.md](EXCLUDED.md) | — |
| [`ourlim-config`](https://github.com/SystemConsultantGroup/ourlim-config/tree/442f108ac94d574ad1174345f1446b3f611d9e9a) | ordinary + blocked | notes only pending source-branch verification | `ourlim` |
| [`PDF-config`](https://github.com/SystemConsultantGroup/PDF-config/tree/8bd32a713e794f0ad003baac0b152a0aa2e05f8f) | ordinary | 1 app (internal Service, no routes) | `pdf` |
| [`renovate-config`](https://github.com/SystemConsultantGroup/renovate-config/tree/b08a366f41334fe58c24171d0988997b53b04624) | platform | excluded — CronJob dependency bot → [EXCLUDED.md](EXCLUDED.md) | — |
| [`room-reservation-config`](https://github.com/SystemConsultantGroup/room-reservation-config/tree/111b1e6b68243dd85817e9064aafc804da8314ae) | ordinary | 2 generated-route apps; backend CORS remains a blocker | `room-reservation-frontend`, `room-reservation-backend` |
| [`scg-apply-config`](https://github.com/SystemConsultantGroup/scg-apply-config/tree/0872c32185f370d921d5cf5d046a0fdde8438671) | ordinary | 1 app (same-host FE/BE) | `scg-apply` |
| [`scg-home-config`](https://github.com/SystemConsultantGroup/scg-home-config/tree/a33ebebc755a34d7dc286ec2210d3b2c0ee1713f) | ordinary | FE custom draft; BE notes only pending hostname/path decision | `scg-home-fe`, `scg-home-be` |
| [`SCG-Monitoring-Config`](https://github.com/SystemConsultantGroup/SCG-Monitoring-Config/tree/7482cc7dd43ad31c2926a8a9f605057b85e1a9d3) | platform/stateful | excluded — kube-prometheus-stack, PVCs, RBAC, CRDs → [EXCLUDED.md](EXCLUDED.md) | — |
| [`scg-new-2022-config`](https://github.com/SystemConsultantGroup/scg-new-2022-config/tree/1cdd880cce8976e1fbcef0f247dc080b9c7fea5b) | superseded | excluded — homepage now owned by `scg-home-config` → [EXCLUDED.md](EXCLUDED.md) | — |
| [`SCG-SSO-config`](https://github.com/SystemConsultantGroup/SCG-SSO-config/tree/6a4faa679c7046230b31c5b274d04c2f44d400e7) | platform | excluded — org Keycloak identity provider → [EXCLUDED.md](EXCLUDED.md) | — |
| [`shortener-config`](https://github.com/SystemConsultantGroup/shortener-config/tree/d17cbce97c87a4e4e43db090a9ab5efb48a84623) | ordinary | 2 apps (host-separated) | `shortener-frontend`, `shortener-api` |
| [`skku-alumni-config`](https://github.com/SystemConsultantGroup/skku-alumni-config/tree/fa2a05383cd92bcfb89d675f075b6e2023d52a5b) | ordinary | 3 generated-route apps + Redis excluded; BE CORS remains a blocker | `alumni-user`, `alumni-admin`, `alumni-be` |
| [`S-TOP-config`](https://github.com/SystemConsultantGroup/S-TOP-config/tree/b1da36340ed120dce66cf50d30bf22002e157ac1) | ordinary | 1 app (same-host FE/BE) | `s-top` (custom) |
| [`timetable-planner-config`](https://github.com/SystemConsultantGroup/timetable-planner-config/tree/47b3bcc7d8289fb27f487f9aed398bc37fc30a93) | ordinary | 2 apps (host-separated) + Redis excluded | `timetable-planner-frontend`, `timetable-planner-backend` |

Components excluded *inside* otherwise-ordinary repos (recorded, not registered):
`alumni-redis` and `timetable-planner-redis` (stateful Redis, chart v1 non-goal). Both are detailed in [`EXCLUDED.md`](EXCLUDED.md).

## Migration order (spec §13 step 12 sequence)

`*` = no `meta.yaml` yet (blocked — intent draft not complete). All steps are gated on the
§13/§14 implementation proofs and the per-application blockers in each `PORTING.md`.

1. **`icc-haedong-seminar-reservation`** — simplest one image / one Service / root route;
   validate chart, namespace, Secret, Gateway and DNS first.
2. **`icc-lecture-enrollment`** — same shape with port 8090 and external
   MySQL/MinIO/SMTP dependency checks.
3. **`cse-undergrad-gp-manage`** — validate the managed-primary + external-alias route
   intent and 2g/redirect behavior.
4. **Simple split components:** `attendance-checker-frontend`, `room-reservation-frontend`,
   `shortener-frontend`, `timetable-planner-frontend`, `timetable-planner-backend` — validate
   separate registrations and testing promotion.
5. **Remaining split and multi-workload applications:** `exhibition-frontend`,
   `exhibition-backend`, `room-reservation-backend`, `shortener-api`, `s-top`, `scg-apply`,
   and `icc-grad-dissertation-manage`. Gate the custom routes only for `exhibition-backend`
   and `s-top`; retain the documented port, CORS, domain, and publishing gates for the others.
   `attendance-checker-backend`* waits for a runnable image and settled listener/route.
6. **Alumni:** `alumni-user`, `alumni-admin`, `alumni-be` — after private-repository access,
   CORS decision, FE build-time configuration, and Redis ownership are resolved.
7. **scg-home:** `scg-home-fe` (custom route) and `scg-home-be`* — after repairing the broken
   prod overlay evidence and deciding hostname/path, redirect/CORS, and school-domain DNS/TLS.
8. **Conditional stale apps:** `pdf` (meta draft exists, but activity evidence is stale —
   confirm the pipeline) and `ourlim`* (source-repo production branch and image publication
   unresolved). `cs-grad-thesis` stays excluded (see [`EXCLUDED.md`](EXCLUDED.md)).
9. **Platform work:** monitoring, cloudflared, office, Renovate, codex-lb, SCG-SSO and Redis
   move on separate platform tracks; none go through the generic application chart
   (see [`EXCLUDED.md`](EXCLUDED.md)).

## Custom-route drafts (`routes/`)

nginx intent translated to constrained Gateway API `HTTPRoute` sources only where the
§5.6 allowlist can express it (core filters only; no annotations; platform injects
namespace and parentRefs):

| Application | nginx intent → HTTPRoute filter |
| --- | --- |
| `exhibition-backend` | `/v1/` prefix rewrite → `URLRewrite` `ReplacePrefixMatch` |
| `scg-home-fe` | production-only `/seminar` permanent redirect → `RequestRedirect` 308 with full-path replacement |
| `s-top` | `/v1(/|$)(.*)` rewrite `/$2` → `URLRewrite` `ReplacePrefixMatch` |

nginx annotations that have no Gateway API/chart equivalent are **not** carried:
`proxy-body-size` (all upload apps), `ssl-redirect`, `app-root`, buffering/timeouts,
Prometheus scrape annotations. nginx-generated CORS is also not approximated with header modifiers; it remains an application or future proven Gateway capability. No replacement policies were invented.

## Cross-cutting unresolved spec gaps (see also per-app PORTING.md)

1. **Domain model binary.** `external: false` requires an operational ExternalDNS zone
   (currently only `scg.sh`); `external: true` is HTTP-only and gated on school-firewall
   source-range validation. Legacy school-zone DNS + in-cluster cert-manager TLS
   (`scg.skku.ac.kr`, `cs.skku.edu`, `icc.skku.ac.kr`, `*.skku.ac.kr`) fits neither mode
   (§5.3). Nearly every production registration is blocked on this plus the
   missing zone-allowlist source of truth.
2. **Custom-route core filters still need implementation proof.** V1 permits only `URLRewrite` and `RequestRedirect`; Gateway API schema and Cilium conformance proof (§5.6/§13.11) must precede any sync.
3. **Request body-size limits are unrepresentable** in generated and custom routes
   (no HTTPRoute filter, no annotations).
4. **CORS has no platform capability;** use application-side CORS until Gateway API `CORS` support and environment-specific origins are proven.
5. **Attestation gap:** no legacy workload has usable workflow-bound provenance; available GitHub image workflows disable it and some workloads have no trusted publisher. First `lock.yaml` entries require rebuilt, attested images.
6. **Private application repos** (`skku-alumni-*`, `ICC-haedong-*`) require org GitHub
   App access for workflow/preview paths.
