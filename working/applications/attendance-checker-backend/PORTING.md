# PORTING notes: attendance-checker-backend

Legacy evidence: [SystemConsultantGroup/attendance-checker-config@6a9f6e7](https://github.com/SystemConsultantGroup/attendance-checker-config/tree/6a9f6e78c740bac6706990d7d98b203382868dee)
(2026-08-07 snapshot). **No `meta.yaml`:** the current source does not provide a runnable workload, verified listener, or settled route.

## Candidate shape after the application is repaired
- The Service targets 8080 while the Deployment declares 8000; choose neither until a real image proves its listener.
- `env.from.secrets: [attendance-checker-be-secret]` mirrors legacy `envFrom.secretRef`.
- Legacy route `/v1/(.*)` conflicts with backend controllers under `/api/*`; decide the public prefix when a real image ships.
- Legacy BE CORS annotation treated as dead config (no cross-origin callers in current
  frontend source) and dropped; custom routes could not express it anyway.

## Blockers
- **No runnable image:** the checked-in Dockerfile is an `alpine` echo-loop stub; the deployed
  image serves no port. Needs a real multi-stage Dockerfile and verified listener (B2).
- MySQL dependency (JPA, `mysql-connector-j`) requires the platform database story (B4).
- Committed plaintext DB/JWT credentials in `backend/src/main/resources/application.properties`
  must move to Secret provisioning; nothing copied into meta.yaml literals (P5).

## Unsupported legacy behavior (not ported)
- Ingress/TLS resources, empty legacy Secret payload, `latest` tag + `provenance: false` build.
