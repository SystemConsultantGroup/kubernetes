# s-top

S-TOP, ported from [`S-TOP-config`](https://github.com/SystemConsultantGroup/S-TOP-config). No public domain is
declared yet; see the [legacy port status](../../working/LEGACY_CONFIG_PORT.md)
before cutover.

| Workload | Source | Port | Legacy production route |
| --- | --- | --- | --- |
| be | [`S-top-backend`](https://github.com/SystemConsultantGroup/S-top-backend) | 8000 | `s-top.cs.skku.edu/v1(/\|$)(.*)` rewritten to `/$2` |
| fe | [`S-top-frontend`](https://github.com/SystemConsultantGroup/S-top-frontend) | 3000 | `s-top.cs.skku.edu/` |

The backend image is published from a personal Docker Hub namespace
(`jcy0308`); move it to an organization registry when the repository adopts the
shared delivery workflow.

## Vault values

Path: `kv/applications/s-top/production/be`.

Keys: `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`,
`SPRING_DATASOURCE_PASSWORD`, `MINIO_URL`, `MINIO_BUCKET`, `MINIO_SECRET`,
`NOTION_SECRET`, `NOTION_DB_DATASET`, `NOTION_DB_JOBINFO`,
`NOTION_DB_MODEL`, `OAUTH_CLIENT_ID`, `OAUTH_REDIRECT_URI`,
`WEB_REDIRECT_URI`, `ADMIN_EMAIL`, `STOP_EMAIL`, `STOP_EMAIL_PASSWORD`.
