# PORTING notes: room-reservation-frontend

Legacy evidence: [SystemConsultantGroup/room-reservation-config@111b1e6](https://github.com/SystemConsultantGroup/room-reservation-config/tree/111b1e6b68243dd85817e9064aafc804da8314ae)
(2026-08-07 snapshot). Testing + production (`branches.testing: develop`, `branches.production: main`).

## Assumptions
- `port: 3000`; TCP readiness default — neither source app exposes a health endpoint (no
  actuator, no `/health`).
- `semi.room.scg.skku.ac.kr`, `external: false` maps in-cluster cert-manager TLS.
- Legacy root regex `/(.*)` + rewrite `/$1` is a no-op at `/`; generated `PathPrefix /` is
  equivalent.
- `develop` testing branch inferred from `cd-dev` workflows; confirm it still exists (dev tag
  SHA equals `main` HEAD — branches may have converged).

## Blockers
- `scg.skku.ac.kr` zone not operational in ExternalDNS (only `.example` config exists).
- Legacy `-prod`/`-dev` split image repos are inexpressible (single canonical `Workload.image`):
  CI must publish both branches to the canonical `-prod` repo, or the schema needs a
  per-environment image override (spec gap).
- `NEXT_PUBLIC_API_URL` is read at runtime via `next-runtime-env` client-side and `process.env`
  server-side — CI build env must supply it consistently for each environment.

## Unsupported legacy behavior (not ported)
- Legacy dev hostnames/namespaces (`reservation-dev.scg.skku.ac.kr`, `reservation-prod`);
  derived names replace them.
