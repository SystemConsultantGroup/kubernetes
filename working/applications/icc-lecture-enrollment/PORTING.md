# PORTING notes: icc-lecture-enrollment

Legacy evidence: [SystemConsultantGroup/ICC-lecture-enrollment-config@c851b86](https://github.com/SystemConsultantGroup/ICC-lecture-enrollment-config/tree/c851b8607c426327aea2ac847fd421a38b8496e1)
(2026-08-07 snapshot). Production-only (`branches.production: master`); one image (FE+BE in one container), one workload `app`.

## Assumptions
- `port: 8090` (containerPort + Service 80→8090).
- TCP readiness default; the sweep's inferred `/` health path is **not** claimed (no legacy
  probes, no verified health endpoint).
- `profsystem.icc.skku.ac.kr`, `external: false` maps in-cluster cert-manager TLS; base
  `blabla.scg.skku.ac.kr` is a placeholder, not an alias.
- 28-key `icc-lecture-enrollment-secret` provisioned externally; external MySQL/MinIO/SMTP
  reachability required.

## Blockers
- `icc.skku.ac.kr` zone not in the ExternalDNS allowlist; `external` alternative would be an
  HTTP-only regression for a session/login app (spec gap: no external-HTTPS mode).
- Legacy workflow `provenance: false`, SHA+`latest` tags → no attested digest until the §7
  workflow replaces it.

## Unsupported legacy behavior (not ported)
- `proxy-body-size: 200m` (Excel/upload paths), nginx Ingress/TLS, `imagePullPolicy: Always`.
