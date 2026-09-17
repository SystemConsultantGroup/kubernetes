# Alumni onboarding

Prepare a parallel deployment without changing legacy services, alumni-proxy,
DNS, or public routing. This directory is intentionally not watched by Argo CD:
the initial application images do not exist yet. Do not commit fabricated image
digests or source revisions just to activate the application.

## Order of operations

1. Review the frontend/backend PRs and merge their platform workflow and Dockerfile
   changes to main. Every main push attempts platform delivery; until production
   locks and GitHub App credentials exist, the initial delivery can fail.
   Existing legacy CD still runs according to its unchanged triggers.
1. In the frontend repository set the Actions repository variable
   `PLATFORM_NEXT_PUBLIC_API_BASE_URL`. For internal-only startup verification,
   `http://alumni-be.alumni-production.svc.cluster.local` is the new API address
   (the Service port is 80). This address is NOT browser-accessible. Later browser
   testing needs an accessible API URL and a new frontend image build.
1. Run the `Platform deployment` workflow manually on main in each app repository.
   Download `platform-lock-user`, `platform-lock-admin`, and `platform-lock-be`.
   These bootstrap runs only publish images; they do not dispatch deployment.
   Make all three GHCR packages publicly pullable before onboarding because the
   managed chart has no imagePullSecrets. No credentials or private source should
   be included in the images.
1. From this repository root, register the downloaded locks:
   ```sh
   python3 onboarding/alumni/register.py --user /path/user.json --admin /path/admin.json --be /path/be.json
   ```
   Include the generated `applications/alumni/` in the infrastructure PR, inspect
   its source SHAs and image digests against the successful builds, and run local
   repository validation. This step is required before the three-app onboarding
   PR is ready to merge. The script refuses to overwrite an existing application.
1. Prepare the storage secrets described in
   [alumni-storage](../../applications/alumni-storage/README.md), then merge the
   reviewed infrastructure PR. Argo CD deploys storage and the managed app.
1. Obtain an application database/account on `alumni-haproxy.mysql:3306` and grant
   schema-scoped permissions needed by Flyway. Do not use system/root accounts.
   Create the MinIO bucket/application account, then populate the backend Vault
   path below. Until every required key exists, the backend container stays
   blocked with a missing-secret/key configuration status. Argo CD will not be
   fully Healthy during this deliberate wait; do not disable Flyway to bypass it.
1. Configure `KUBERNETES_APP_ID` and `KUBERNETES_APP_PRIVATE_KEY` in both app
   repositories as described in the shared workflow guide. Once production locks
   are on main, rerun any failed initial Actions delivery. Future app-main pushes
   always use the shared delivery workflow; previews/testing are deliberately
   not enabled. Backend tests must still pass before image publication.

## Backend Vault values

Path: `kv/applications/alumni/production/be`.

Required keys: `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `AUTH_JWT_SECRET`,
`MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `SPRING_DATA_REDIS_PASSWORD`.
The last value must match the storage Redis `REDIS_PASSWORD`.
Do not create a partially populated path; the metadata requires each key.

The metadata supplies the new internal DB/Redis/MinIO addresses and bucket
`alumni`; explicit environment values take precedence over Vault values.
Firebase credentials are forced empty for this initial environment to avoid
sending real production push notifications.

This phase checks startup, DB migrations, readiness, and internal connectivity.
Existing production CORS, cookie-domain and member URL settings are not a working
browser test configuration for the new environment. Before external access,
review those settings, Firebase, API build URLs, storage backup, and TLS together.

## Validation and rollback

Run `nix fmt -- --ci .` and `nix flake check` in the supported Nix environment.
Render the custom storage Kustomization and the generated managed application.
Verify there are no public routes and no changes to alumni-proxy or MySQL.
Check source/image matches, non-root execution, required-secret behavior, and
health after the real credentials are registered.

Image build or lock-update failures must be retried in GitHub Actions: Argo CD
Sync cannot publish an image or update Git locks. Once locks are committed, retry
cluster reconciliation using Sync after resolving the underlying problem.
Roll back application image locks in Git. Removing an app causes Argo CD pruning; preserve
storage claims and do not treat application rollback as a DB migration rollback.
