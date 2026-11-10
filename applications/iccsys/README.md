# iccsys

The ICC undergraduate management system, ported from
[`iccsys-config`](https://github.com/SystemConsultantGroup/iccsys-config). Production and testing both build from
[`iccsys-new`](https://github.com/SystemConsultantGroup/iccsys-new). No public domain is declared yet; see the
[legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutover.

| Workload | Port | Legacy production route | Legacy QA route |
| --- | --- | --- | --- |
| web | 8091 | `iccsys.skku.ac.kr/` | `qa.iccsys.scg.skku.ac.kr/` |

Legacy production tracked the mutable `latest` tag. The production lock pins
the digest that tag resolved to when ported, whose image labels identify source
commit `525e6c3b`. The legacy liveness probe
(`/iccsys/health/liveness`) is not expressible in the shared chart; only the
readiness probe is carried over.

## Vault values

Paths: `kv/applications/iccsys/{production,testing}/web`.

Production keys: `NODE_ENV`, `PROD_SERVER_PORT` (must be `8091`),
`SESSION_SECRET`, `UPLOAD_BASE_PATH`, `PROD_ICC_UPLOAD_PATH`,
`PROD_ICCSYS_UPLOAD_PATH`, `PROD_PERMIT_STUDENT_COUNT`,
`PROD_PERMIT_STUDENT_COUNT_SEMICON`, `PROD_DB_HOST`, `PROD_DB_NAME`,
`PROD_DB_USERNAME`, `PROD_DB_PASSWORD`, `PROD_DB_DIALECT`,
`PROD_DB_TIMEZONE`, `PROD_DB_LOGGING`, `MINIO_ENDPOINT`, `MINIO_PORT`,
`MINIO_USE_SSL`, `MINIO_BUCKET_NAME`, `MINIO_OBJECT_PREFIX`,
`MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`.

Testing keys use the `QA_` prefix in place of `PROD_`, with `QA_DB_DATABASE`
instead of `PROD_DB_NAME` and unprefixed `PERMIT_STUDENT_COUNT` and
`PERMIT_STUDENT_COUNT_SEMICON`.
