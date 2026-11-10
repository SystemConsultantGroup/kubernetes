# timetable-planner

SKKedule, ported from [`timetable-planner-config`](https://github.com/SystemConsultantGroup/timetable-planner-config).
Its Redis cache runs in [`timetable-planner-storage`](../timetable-planner-storage/README.md).
No public domain is declared yet; see the
[legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutover.

| Workload | Source | Port | Legacy production route |
| --- | --- | --- | --- |
| be | [`timetable-planner-backend`](https://github.com/SystemConsultantGroup/timetable-planner-backend) | 8080 | `api.skkedule.scg.skku.ac.kr/` |
| fe | [`timetable-planner-frontend`](https://github.com/SystemConsultantGroup/timetable-planner-frontend) | 3000 | `skkedule.scg.skku.ac.kr/` |

## Vault values

Path: `kv/applications/timetable-planner/production/be`.

Keys: `COURSEPLANNER_DB_URL`, `COURSEPLANNER_DB_USERNAME`,
`COURSEPLANNER_DB_PASSWORD`, `REDIS_PASSWORD`, `JWT_SECRET`,
`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `EVERYTIME_COOKIE`,
`EVERYTIME_COOKIE_ENCRYPTION_SECRET`, `MCP_OAUTH_CLIENT_SECRET`,
`MCP_OAUTH_REDIRECT_URIS`, `MCP_REVIEW_LOGIN_PASSWORD`,
`OPENAI_APPS_CHALLENGE_TOKEN`.

`REDIS_HOST` and `REDIS_PORT` are set in `meta.yaml` and override any Vault
value. `REDIS_PASSWORD` must equal the storage value.
