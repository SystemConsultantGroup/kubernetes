# icc-lecture-enrollment

The ICC lecture assignment system, ported from
[`ICC-lecture-enrollment-config`](https://github.com/SystemConsultantGroup/ICC-lecture-enrollment-config).
No public domain is declared yet; see the
[legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutover.

| Workload | Source | Port | Legacy production route |
| --- | --- | --- | --- |
| web | [`ICC-lecture-enrollment`](https://github.com/SystemConsultantGroup/ICC-lecture-enrollment) | 8090 | `profsystem.icc.skku.ac.kr/` |

## Vault values

Path: `kv/applications/icc-lecture-enrollment/production/web`.

Keys: `PORT` and `APP_PORT` (both must be `8090`), `APP_TITLE`,
`APP_INDEX_PATH`, `APP_SRC_PATH`, `APP_VIEW_PATH`, `UPLOAD_PATH`,
`SESSION_KEY`, `SESSION_SECRET`, `DB_HOST`, `DB_PORT`, `DB_NAME`,
`DB_USER`, `DB_PASSWORD`, `DB_CHARSET`, `DB_DIALECT`, `DB_TIMEZONE`,
`DB_LOGGING`, `DB_MULTIPLE_STATEMENTS`, `MINIO_ENDPOINT`, `MINIO_PORT`,
`MINIO_BUCKET`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `SMTP_USER`,
`SMTP_PASS`.
