# PORTING notes: icc-grad-dissertation-manage

Legacy evidence: [SystemConsultantGroup/ICC-grad-dissertation-manage-config@d5f320b](https://github.com/SystemConsultantGroup/ICC-grad-dissertation-manage-config/tree/d5f320b702f6600fdc22de3a980c0c3c0c0beb35)
(2026-08-07 snapshot). Production-only; same-host FE/BE = one application with generated routes (`/` → fe,
`/v1` → be). This is the spec §5.1 example shape.

## Assumptions
- FE production branch `main` (workflow trigger), despite repo default `develop`.
- BE port 4000 (containerPort/Service evidence); app binds `APP_PORT` from
  `prod-ice-grad-secret` — verify the Vault value equals 4000.
- `resources.requests.cpu: "1"` preserved from legacy BE Deployment.
- TCP readiness default both workloads; `/metrics` exists but no probe evidence.
- FE API endpoint (`NEXT_PUBLIC_API_ENDPOINT`) is baked at build from a GitHub secret; the
  reusable workflow must reproduce the `.env` build step with a production-safe secret.

## Blockers
- `grad.icc.skku.ac.kr` is outside the only operational ExternalDNS zone (`scg.sh`); the
  `icc.skku.ac.kr` zone is not configured. `external: false` is the closest fit but
  registration CI must reject until the zone is added (spec gap: no "cluster-served domain in
  an unmanaged DNS zone" mode).
- BE legacy `proxy-body-size: 200m` (file uploads) is inexpressible in generated and custom
  routes.

## Unsupported legacy behavior (not ported)
- nginx Ingress/TLS, obsolete `regcred` pull secret (public images), stale QA workflow path.
