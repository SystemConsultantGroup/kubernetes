# PORTING notes: exhibition-frontend

Legacy evidence: [SystemConsultantGroup/exhibition-config@a0b7ead](https://github.com/SystemConsultantGroup/exhibition-config/tree/a0b7ead72f7e2a777d7d2b9474ce4e3b669d8cf0)
(2026-08-07 snapshot). Production-only (`branches.production: main`).

## Assumptions
- `port: 3000` (Dockerfile EXPOSE/npm start + Service targetPort); TCP readiness default — no
  health endpoint (no actuator/health route anywhere).
- The canonical `scg.sh` host and all six legacy aliases are retained with managed HTTPS intent.
- No runtime env: all `NEXT_PUBLIC_*` values are baked at image build time (workflow writes
  `.env` before build).

## Blockers / uncertainties
- Four aliases are on school-owned zones with no supported DNS/TLS mode. They remain in the draft so cutover cannot silently drop them; owners may instead approve their retirement.
- No `lock.yaml` (digests unavailable; workflows publish `provenance: false`).

## Unsupported legacy behavior (not ported)
- `gitops-tls` cert-manager TLS, nginx Ingress, `imagePullPolicy: Always`.
