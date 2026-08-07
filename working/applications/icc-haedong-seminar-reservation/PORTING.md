# PORTING notes: icc-haedong-seminar-reservation

Legacy evidence: [SystemConsultantGroup/ICC-haedong-seminar-reservation-config@58e4f2e](https://github.com/SystemConsultantGroup/ICC-haedong-seminar-reservation-config/tree/58e4f2e22fbecf4fcc2001b4ad885320d22fbd52)
(2026-08-07 snapshot). Production-only (`branches.production: master`); spec §13 step 12 first-migration candidate.

## Assumptions
- `port: 3000` (containerPort + Service targetPort); TCP readiness default — no legacy probe,
  no health path.
- `env.from.secrets: [icc-haedong-reservation-secret]`; Secret also carries `APP_PORT` — verify
  it equals 3000 (the Deployment declares 3000; the app may bind the env value).
- `seminar.scg.skku.ac.kr`, `external: false` maps legacy in-cluster cert-manager TLS.
- Source repo is **private**; org GitHub App access needed for workflow/preview paths.

## Blockers
- `scg.skku.ac.kr` not in the ExternalDNS zone allowlist (currently `scg.sh` only).
- Attestation: legacy workflow `provenance: false` + `latest` tags; first `lock.yaml` requires
  rebuilt, attested images (re-publish, not digest-fill).
- Legacy workflow directly rewrites the config repo via `ACTION_TOKEN` — the non-authoritative
  writer the platform removes.

## Unsupported legacy behavior (not ported)
- `proxy-body-size: 200m` annotation; base placeholder host `blabla.scg.skku.ac.kr`;
  `imagePullPolicy: Always`.
