# PORTING notes: shortener-api

Legacy evidence: [SystemConsultantGroup/shortener-config@d17cbce](https://github.com/SystemConsultantGroup/shortener-config/tree/d17cbce97c87a4e4e43db090a9ab5efb48a84623)
(2026-08-07 snapshot). Testing + production (`branches.testing: develop`, `branches.production: main`). Domain `api.scg.sh` with
additional apex `scg.sh`.

## Assumptions
- `port: 8000` (Spring Boot, `server.port: 8000`); TCP readiness default.
- Both hosts in the operational `scg.sh` zone → managed.
- nginx regex `/(.*)` + rewrite `/$1` is a path no-op → generated `PathPrefix /`; CORS is
  handled in-app (`SecurityConfig` allowed-origins `[app.scg.sh, scg.sh]`), so the ingress
  `enable-cors` annotation is droppable (prod-safe; QA-notable).

## Blockers / uncertainties
- **API hostname contract (highest risk):** the backend gates controllers by Host —
  `RedirectionController` only on `scg.sh` (slug base), `UserController`/`UrlController` only
  on `app.api-base-domain` = `api.shortener.scg.skku.ac.kr` (a hostname **absent from the
  legacy ingress**); only Analytics is ungated. The FE's real API base is the build secret
  `API_ENDPOINT_PROD`. Live traffic validation is mandatory before cutover. If host gates must
  align to platform hostnames, the draft sets `APP_API_BASE_DOMAIN=api.scg.sh` and
  `APP_SLUG_BASE_DOMAIN=scg.sh`; confirm Spring Boot relaxed binding and traffic behavior before cutover.
- **`scg.sh` apex ownership:** the slug domain is the managed zone's apex; confirm no other
  platform service needs it and ExternalDNS apex-record behavior (spec gap: no apex guidance).
- `shortener-secret` provisioning in production/testing/preview namespaces (spec §11 absent).
- QA runtime is fragile (no `application-qa.yml`, null host gate, truncated secret) — validate
  before relying on the testing environment.

## Unsupported legacy behavior (not ported)
- Ingress CORS annotation, nginx rewrite, QA hostnames.
