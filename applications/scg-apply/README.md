# scg-apply

The SCG recruitment application site, ported from
[`scg-apply-config`](https://github.com/SystemConsultantGroup/scg-apply-config). No public domain is declared yet;
see the [legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutover.

| Workload | Source | Port | Legacy production route |
| --- | --- | --- | --- |
| be | [`scg-apply-backend`](https://github.com/SystemConsultantGroup/scg-apply-backend) | 8000 | `apply.scg.skku.ac.kr/v1` |
| fe | [`scg-apply-frontend`](https://github.com/SystemConsultantGroup/scg-apply-frontend) | 3000 | `apply.scg.skku.ac.kr/` |

## Vault values

Path: `kv/applications/scg-apply/production/be`.

Keys: `APP_ENV`, `APP_PORT` (must be `8000`), `DATABASE_URL`,
`JWT_SECRET`, `MINIO_END_POINT`, `MINIO_PORT`, `MINIO_BUCKET_NAME`,
`MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`.
