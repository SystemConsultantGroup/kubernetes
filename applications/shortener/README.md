# shortener

The SCG URL shortener, ported from [`shortener-config`](https://github.com/SystemConsultantGroup/shortener-config).
No public domain is declared yet; see the
[legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutover.

| Workload | Source | Port | Legacy production routes |
| --- | --- | --- | --- |
| api | [`scg-url-shortener-backend`](https://github.com/SystemConsultantGroup/scg-url-shortener-backend) | 8000 | `api.scg.sh/`, `scg.sh/` |
| fe | [`scg-url-shortener-frontend`](https://github.com/SystemConsultantGroup/scg-url-shortener-frontend) | 3000 | `app.scg.sh/` |

The legacy API ingress enabled CORS for `https://app.scg.sh`.

## Vault values

Path: `kv/applications/shortener/production/api`.

Keys: `SPRING_PROFILES_ACTIVE`, `SPRING_DATASOURCE_URL`,
`SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `JWT_SECRET`,
`OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`.
