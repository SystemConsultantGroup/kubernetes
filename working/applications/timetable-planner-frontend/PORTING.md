# PORTING notes: timetable-planner-frontend

Legacy evidence: [SystemConsultantGroup/timetable-planner-config@47b3bcc](https://github.com/SystemConsultantGroup/timetable-planner-config/tree/47b3bcc7d8289fb27f487f9aed398bc37fc30a93)
(2026-08-07 snapshot). Testing + production (`branches.testing: dev`, `branches.production: main`).

## Assumptions
- `port: 3000`; TCP readiness default — no legacy probe, health paths unknown.
- `skkedule.scg.skku.ac.kr`, `external: false` maps in-cluster cert-manager TLS intent.
- No env: all FE config is build-time (`NEXT_PUBLIC_API_BASE_URL` from
  `API_ENDPOINT_PROD`/`API_ENDPOINT_DEV` secrets); CI must repoint per environment (testing →
  derived `*.testing.scg.sh` API host) to avoid a silent FE→prod-API miswire (spec gap I4).

## Blockers
- `scg.skku.ac.kr` ExternalDNS zone is **not operational** (only `scg.sh` filters; the
  `scg.skku.ac.kr` directory is `.example`-only with `REPLACE_ME`).
- Cert issuance path unverified for `scg.skku.ac.kr`: the sole ClusterIssuer uses Cloudflare
  DNS01; if the zone is not on Cloudflare, managed HTTPS cannot be satisfied (the rfc2136
  ExternalDNS example implies a different authoritative server).
- Source workflows publish `provenance: false` and push tags directly into the config repo —
  §7 replacement required.

## Unsupported legacy behavior (not ported)
- Legacy dev hosts (`skkedule-dev.*`), nginx Ingress/TLS, `-dev` image repos.
