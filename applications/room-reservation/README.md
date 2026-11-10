# room-reservation

The SKKU room reservation system, ported from
[`room-reservation-config`](https://github.com/SystemConsultantGroup/room-reservation-config). No public domain is
declared yet; see the [legacy port status](../../working/LEGACY_CONFIG_PORT.md)
before cutover.

| Workload | Source | Port | Legacy production route |
| --- | --- | --- | --- |
| be | [`room-reservation-backend`](https://github.com/SystemConsultantGroup/room-reservation-backend) | 8000 | `api.reservation.scg.skku.ac.kr/` |
| fe | [`room-reservation-frontend`](https://github.com/SystemConsultantGroup/room-reservation-frontend) | 3000 | `semi.room.scg.skku.ac.kr/` |

The legacy backend ingress enabled CORS.

## Vault values

| Path | Keys |
| --- | --- |
| `kv/applications/room-reservation/production/be` | `SPRING_PROFILES_ACTIVE`, `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_CALLBACK_URI` |
| `kv/applications/room-reservation/production/fe` | `NEXT_PUBLIC_API_URL` |

Next.js inlines `NEXT_PUBLIC_*` values at build time, so the frontend image may
need a rebuild when the API hostname changes.
