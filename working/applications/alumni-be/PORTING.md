# PORTING notes: alumni-be

Legacy evidence: [SystemConsultantGroup/skku-alumni-config@fa2a0538](https://github.com/SystemConsultantGroup/skku-alumni-config/tree/fa2a05383cd92bcfb89d675f075b6e2023d52a5b)
(2026-08-07 snapshot). Generated root route; legacy CORS is not represented by an HTTP header-modifier approximation.

## Assumptions
- Production image repository is `docker.io/scgskku/alumni-be-prod`; the replacement workflow must publish testing commits to the same canonical repository.
- `port: 8000`; TCP readiness default.
- `api.alumni.scg.skku.ac.kr`, managed-domain intent pending a supported school TLS/DNS mode.

## Blockers
- **Redis ownership:** `alumni-be-secret` points at the legacy `alumni-redis-service`. Redis is excluded from chart v1; provide it separately or replace it.
- Implement CORS in the application or prove Gateway API `CORS` filter support in Cilium, including environment-specific origins and preflight behavior.
- Private repository access, attested publishing, Secret provisioning, and the school-domain TLS/DNS decision remain unresolved.

## Unsupported legacy behavior
- Legacy dev hosts, nginx Ingress/TLS, nginx-generated CORS, and the Redis Deployment.
