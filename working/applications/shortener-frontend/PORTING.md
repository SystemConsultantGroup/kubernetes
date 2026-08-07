# PORTING notes: shortener-frontend

Legacy evidence: [SystemConsultantGroup/shortener-config@d17cbce](https://github.com/SystemConsultantGroup/shortener-config/tree/d17cbce97c87a4e4e43db090a9ab5efb48a84623)
(2026-08-07 snapshot). Testing + production (`branches.testing: dev`, `branches.production: main`).

## Assumptions
- `port: 3000` (standalone Next.js); TCP readiness default — no probe evidence.
- `app.scg.sh`, `external: false` — inside the only operational ExternalDNS zone (`scg.sh`).
- FE has no runtime env/secret; `NEXT_PUBLIC_API_DOMAIN` is baked at build from a GitHub
  secret (CI concern per §7, not chart env).

## Blockers / uncertainties
- **Config staleness:** the legacy prod pinned tag predates FE `main` HEAD; cutover should
  rebuild from `main`, not trust the pinned tag (P6).
- Testing/preview FE builds must embed the derived testing/preview API hostname
  (`shortener-api.testing.scg.sh`); the legacy `API_ENDPOINT_` QA secret reference looks
  truncated/broken — repair in the new workflow (P4).

## Unsupported legacy behavior (not ported)
- Legacy QA hosts under `scg.skku.ac.kr` (unconfigured zone) — replaced by derived
  `*.testing.scg.sh`; nginx Ingress/TLS.
