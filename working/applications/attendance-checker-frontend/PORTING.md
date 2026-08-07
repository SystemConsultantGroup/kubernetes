# PORTING notes: attendance-checker-frontend

Legacy evidence: [SystemConsultantGroup/attendance-checker-config@6a9f6e7](https://github.com/SystemConsultantGroup/attendance-checker-config/tree/6a9f6e78c740bac6706990d7d98b203382868dee)
(2026-08-07 snapshot). Production-only (`branches.production: main`); no testing release.

## Assumptions
- `port: 3000` from Dockerfile EXPOSE 3000 + Service 80→3000; TCP readiness default (no
  legacy probe, no health endpoint).
- `domain.external: false` maps legacy in-cluster cert-manager TLS; blocked until
  `scg.skku.ac.kr` is in the ExternalDNS zone allowlist.

## Blockers
- **State-in-image:** the app persists all data to a container-local `data/db.json`
  ([`src/lib/db.ts`](https://github.com/SystemConsultantGroup/attendance-checker-frontend/blob/13b453f8b39cc57b2d10d7e7eb52b068fdf3e85d/src/lib/db.ts)); every platform rollout re-seeds and destroys attendance data.
  Production cutover blocked until persistence moves to the backend's MySQL (platform-side) or
  an approved store. Spec has no rule for container-local state (spec gap S1).
- No `lock.yaml` until the attested publish workflow exists.

## Unsupported legacy behavior (not ported)
- Ingress/cert-manager/TLS secret resources; Image Updater-style config-repo tag commits.
