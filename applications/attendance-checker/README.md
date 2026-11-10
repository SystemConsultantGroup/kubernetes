# attendance-checker

Ported from [`attendance-checker-prod-config`](https://github.com/SystemConsultantGroup/attendance-checker-prod-config)
(production) and [`attendance-checker-config`](https://github.com/SystemConsultantGroup/attendance-checker-config)
(testing). No public domain is declared yet; see the
[legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutover.

| Workload | Production source | Testing source | Port | Legacy production route |
| --- | --- | --- | --- | --- |
| be | [`attendance-checker-be-prod`](https://github.com/SystemConsultantGroup/attendance-checker-be-prod) | [`attendance-checker-backend`](https://github.com/SystemConsultantGroup/attendance-checker-backend) | 8080 | `api.taghedge.scg.skku.ac.kr/` |
| fe | [`attendance-checker-fe-prod`](https://github.com/SystemConsultantGroup/attendance-checker-fe-prod) | [`attendance-checker-frontend`](https://github.com/SystemConsultantGroup/attendance-checker-frontend) | 3000 | `taghedge.scg.skku.ac.kr/` |

The legacy testing hostnames were `attendance.scg.skku.ac.kr` and
`api.attendance.scg.skku.ac.kr`. The legacy backend ingress enabled CORS and a
larger request body size; reproduce both when declaring its domain.

## Vault values

Paths: `kv/applications/attendance-checker/{production,testing}/be`.

Keys: `DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`,
`GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`, `JWT_SECRET_KEY`,
`MINIO_ENDPOINT`, `MINIO_BUCKET`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`,
`SPRING_JPA_HIBERNATE_DDL_AUTO`, `SPRING_SQL_INIT_MODE`.
