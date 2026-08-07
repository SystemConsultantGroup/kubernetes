# PORTING notes: alumni-admin

Legacy evidence: [SystemConsultantGroup/skku-alumni-config@fa2a0538](https://github.com/SystemConsultantGroup/skku-alumni-config/tree/fa2a05383cd92bcfb89d675f075b6e2023d52a5b)
(2026-08-07 snapshot). Testing + production (`branches.testing: develop`, `branches.production: main`).

## Assumptions
- `port: 3000`; TCP readiness default.
- `admin.alumni.scg.skku.ac.kr`, `external: false`.
- Same monorepo (`skku-alumni-frontend`) as alumni-user; repo reuse across applications is
  explicitly allowed (§5.2). The FE monorepo release workflow must invoke the reusable publish
  workflow twice (alumni-user, alumni-admin) — two atomic preview mutations from one PR.

## Blockers
- `scg.skku.ac.kr` ExternalDNS zone not operational; `provenance: false` builds; private repos.

## Unsupported legacy behavior (not ported)
- Legacy dev hosts, nginx Ingress/TLS, `-dev` image repos, `latest` tags.
