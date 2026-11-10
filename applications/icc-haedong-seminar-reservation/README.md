# icc-haedong-seminar-reservation

The Haedong academic information room reservation system, ported from
[`ICC-haedong-seminar-reservation-config`](https://github.com/SystemConsultantGroup/ICC-haedong-seminar-reservation-config).
No public domain is declared yet; see the
[legacy port status](../../working/LEGACY_CONFIG_PORT.md) before cutover.

| Workload | Source | Port | Legacy production route |
| --- | --- | --- | --- |
| web | [`ICC-haedong-seminar-reservation`](https://github.com/SystemConsultantGroup/ICC-haedong-seminar-reservation) | 3000 | `seminar.scg.skku.ac.kr/` |

## Vault values

Path: `kv/applications/icc-haedong-seminar-reservation/production/web`.

Keys: `APP_PORT` (must be `3000`), `SESSION_SECRET`, `DB_HOST`,
`DB_PORT`, `DB_NAME`, `DB_USER`, `DB_USERNAME`, `DB_PASSWORD`,
`DB_DIALECT`, `DB_TIMEZONE`, `DB_LOGGING`, `DB_MULTIPLE_STATEMENTS`,
`RECAPTCHA_PUBLIC_KEY`, `RECAPTCHA_PRIVATE_KEY`.
