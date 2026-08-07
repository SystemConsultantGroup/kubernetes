# PORTING notes: s-top

Legacy evidence: [SystemConsultantGroup/S-TOP-config@b1da363](https://github.com/SystemConsultantGroup/S-TOP-config/tree/b1da36340ed120dce66cf50d30bf22002e157ac1)
(2026-08-07 snapshot). Testing + production (`branches.testing: develop`, `branches.production: main`); same-host FE/BE = one
application. `routes: custom` with one constrained HTTPRoute (path split + rewrite).

## Assumptions
- Ports 3000 (FE) / 8000 (BE); TCP readiness default.
- nginx `/v1(/|$)(.*)` + rewrite `/$2` intent → `PathPrefix /v1` + `URLRewrite
  ReplacePrefixMatch /`, with `/` fallback to FE. `/v1` wins by Gateway API path specificity.
- `s-top.cs.skku.edu` retains managed HTTPS intent (`external: false`), blocked until the platform supports the school's chosen DNS/TLS arrangement.
- Testing `develop` maps legacy QA; if owners reject testing, delete `testing: develop` from
  **both** workloads (all-or-none) — nothing else changes.
- Repository canonical case (`S-top-*`) must be confirmed via the GitHub API before
  registration (§5.4 exact-equality validation).

## Blockers
- Domain/TLS decision for `s-top.cs.skku.edu`; managed mode is blocked on an operational DNS/certificate arrangement for `cs.skku.edu`.
- Custom-route capability not proven (§5.6/§13.11).
- Attested publishing: BE image is on a personal Docker Hub account (`jcy0308/stop-be-prod`)
  with `provenance: false` — must become org-controlled and attested.
- `stop-secret` provisioning in production and testing namespaces.

## Uncertainties / unsupported legacy behavior
- Gateway API `PathPrefix /v1` matches complete path elements, preserving the legacy `/v1` boundary; conformance still requires a traffic test.
- `proxy-body-size: 200m` (uploads to MinIO) unrepresentable.
- Legacy QA (`stop.scg.skku.ac.kr`, `*-qa` images) is not a platform environment; mapped to
  derived testing with canonical images.
- FE `NEXT_PUBLIC_*` values are build-time constants (non-secret) — §7 must allow them as
  non-secret build values from GitHub environments.
