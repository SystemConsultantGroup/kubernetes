# exhibition

The SCG exhibition platform. `manager` was onboarded directly; `be` and `fe`
were ported from [`exhibition-config`](https://github.com/SystemConsultantGroup/exhibition-config). Only `manager`
declares a domain; see the
[legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutting over
`be` and `fe`.

| Workload | Source | Port | Legacy production routes |
| --- | --- | --- | --- |
| manager | [`exhibition-manage`](https://github.com/SystemConsultantGroup/exhibition-manage) | 3000 | — |
| be | [`exhibition-backend`](https://github.com/SystemConsultantGroup/exhibition-backend) | 8080 | `api.exhibition.scg.sh/v1/(.*)` rewritten to `/$1` |
| fe | [`exhibition-frontend`](https://github.com/SystemConsultantGroup/exhibition-frontend) | 3000 | `exhibition.scg.sh` and eight other hostnames |

The legacy frontend also served `swgp.exhibition.scg.sh`,
`scg.exhibition.scg.sh`, `eeegrd.exhibition.scg.sh`,
`exhibition.scg.skku.ac.kr`, `exhibition2.scg.skku.ac.kr`,
`swgp.exhb.scg.skku.ac.kr`, `aiswm.exhb.scg.skku.ac.kr`, and
`eeegrd.skku.edu`. The backend ingress stripped the `/v1` prefix, enabled
CORS, disabled request buffering, and raised body size and proxy timeouts;
reproduce these with route rules and filters when declaring its domain.

## Vault values

Path: `kv/applications/exhibition/production/be`.

Keys: `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`,
`SPRING_DATASOURCE_PASSWORD`, `MINIO_ENDPOINT`, `MINIO_PORT`,
`MINIO_BUCKET`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`,
`APP_AUTH_JWT_SECRET`, `APP_AUTH_JWT_ISSUER`,
`APP_AUTH_JWT_ACCESS_TOKEN_EXPIRATION_SECONDS`,
`APP_AUTH_JWT_REFRESH_TOKEN_EXPIRATION_SECONDS`, `APP_AUTH_KAKAO_CLIENT_ID`,
`APP_AUTH_KAKAO_CLIENT_SECRET`, `APP_AUTH_KAKAO_REDIRECT_URI`,
`APP_AUTH_KAKAO_TOKEN_URI`, `APP_AUTH_KAKAO_USER_INFO_URI`,
`APP_CORS_ADMIN_ALLOWED_HOSTS`.
