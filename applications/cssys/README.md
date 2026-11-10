# cssys

The College of Software Convergence undergraduate management system, ported
from [`CSE-undergrad-gp-manage-v2-config`](https://github.com/SystemConsultantGroup/CSE-undergrad-gp-manage-v2-config).
No public domain is declared yet; see the
[legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutover.

| Workload | Source | Port | Legacy production routes |
| --- | --- | --- | --- |
| web | [`CSE-undergrad-gp-manage-v2`](https://github.com/SystemConsultantGroup/CSE-undergrad-gp-manage-v2) | 8091 | `cssys.cs.skku.ac.kr/`, `cssys.skku.ac.kr/` |

The legacy ingresses raised the request body size for uploads.

## Vault values

Path: `kv/applications/cssys/production/web`.

Keys: `PORT` (must be `8091`), `SESSION_SECRET`, `CSSYS_UPLOAD_PATH`,
`CSSYS_PERMIT_STUDENT_COUNT`, `CSSYS_PERMIT_STUDENT_COUNT_SEMICON`,
`DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`,
`DB_DIALECT`, `DB_TIMEZONE`, `DB_LOGGING`, `DB_CONNECT_TIMEOUT`,
`MINIO_ENDPOINT`, `MINIO_PORT`, `MINIO_BUCKET`, `MINIO_ACCESS_KEY`,
`MINIO_SECRET_KEY`.

The container has no volume, so `CSSYS_UPLOAD_PATH` must not be relied on for
durable files.
