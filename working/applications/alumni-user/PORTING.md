# PORTING notes: alumni-user

Legacy evidence: [SystemConsultantGroup/skku-alumni-config@fa2a0538](https://github.com/SystemConsultantGroup/skku-alumni-config/tree/fa2a05383cd92bcfb89d675f075b6e2023d52a5b)
(2026-08-07 snapshot). Testing + production (`branches.testing: develop`, `branches.production: main`).

## Assumptions
- `port: 3000`; TCP readiness default (no legacy probe, no health path).
- `alumni.scg.skku.ac.kr`, `external: false` maps in-cluster cert-manager TLS.
- One canonical image repo `docker.io/scgskku/alumni-user-fe-prod`; the replacement workflow publishes testing commits to that same repository and environments differ by locked digest.
- Legacy FE Secrets are empty (`stringData: {}`); `NEXT_PUBLIC_API_BASE_URL` is a CI build-arg
  (build-time config per §7).

## Blockers
- `scg.skku.ac.kr` not in the ExternalDNS zone allowlist (currently `scg.sh` only).
- Attestation: all legacy builds `provenance: false`, Docker Hub user/pass pushes.
- **Private repos** (`skku-alumni-config`, `skku-alumni-frontend`, `skku-alumni-backend`):
  lock-writer GitHub App and preview builds need read access.

## Unsupported legacy behavior (not ported)
- Legacy dev hosts (`test.alumni.scg.skku.ac.kr`, ...) — testing uses derived
  `*.testing.scg.sh`; nginx Ingress/TLS, `latest` tags.
