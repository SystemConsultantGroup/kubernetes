# scg-sso

The SCG Keycloak build, ported from [`SCG-SSO-config`](https://github.com/SystemConsultantGroup/SCG-SSO-config).
The image is built from [`SCG-SSO`](https://github.com/SystemConsultantGroup/SCG-SSO). No public domain is declared
yet; see the [legacy port status](../../working/LEGACY_CONFIG_PORT.md) before
cutover.

| Workload | Port | Legacy production route |
| --- | --- | --- |
| keycloak | 8080 | `sso.scg.skku.ac.kr/` (with an `app-root` redirect) |

## Vault values

Path: `kv/applications/scg-sso/production/keycloak`.

Keys: `KC_HOSTNAME`, `KC_DB`, `KC_DB_URL_HOST`, `KC_DB_URL_PORT`,
`KC_DB_URL_DATABASE`, `KC_DB_USERNAME`, `KC_DB_PASSWORD`,
`KC_BOOTSTRAP_ADMIN_USERNAME`, `KC_BOOTSTRAP_ADMIN_PASSWORD`.

Keycloak uses the bootstrap administrator only when its database has no admin
user. Pointing this instance at the migrated legacy database preserves realms
and users.
