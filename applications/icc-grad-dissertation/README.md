# icc-grad-dissertation

The ICC graduate dissertation management system, ported from
[`ICC-grad-dissertation-manage-config`](https://github.com/SystemConsultantGroup/ICC-grad-dissertation-manage-config).
No public domain is declared yet; see the
[legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutover.

| Workload | Source | Port | Legacy production route |
| --- | --- | --- | --- |
| be | [`ICC-grad-dissertation-manage-backend`](https://github.com/SystemConsultantGroup/ICC-grad-dissertation-manage-backend) | 4000 | `grad.icc.skku.ac.kr/v1` |
| fe | [`ICC-grad-dissertion-manage-frontend`](https://github.com/SystemConsultantGroup/ICC-grad-dissertion-manage-frontend) | 3000 | `grad.icc.skku.ac.kr/` |

> [!WARNING]
> The backend uses Kafka SASL credentials and pairs with the PDF converter from
> `PDF-config`. The platform provides no Kafka, and the PDF converter has not
> been ported. Resolve both before cutover.

## Vault values

Path: `kv/applications/icc-grad-dissertation/production/be`.

Keys: `APP_ENV`, `APP_PORT` (must be `4000`), `CLIENT_ID`,
`DATABASE_URL`, `JWT_SECRET`, `MINIO_END_POINT`, `MINIO_PORT`,
`MINIO_BUCKET_NAME`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`,
`SASL_MACHANISM`, `SASL_USER`, `SASL_PASSWORD`.
