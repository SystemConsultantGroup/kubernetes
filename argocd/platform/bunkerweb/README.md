# BunkerWeb edge

BunkerWeb provides the public HTTP WAF in front of Envoy Gateway. BunkerWeb
serves ports 80 and 443 on nodes labeled `gateway.scg.sh/listener: "true"`.
Public DNS continues to point to SCC.

```text
Client -> BunkerWeb -> internal Envoy Gateway -> application Service
```

The application chart generates a BunkerWeb Ingress alongside each managed
HTTPRoute. BunkerWeb forwards the original host and path to Envoy. Envoy owns
path routing, redirects, traffic splitting, and CIDR policies. Production hosts
use blocking mode. The platform, testing, and preview hosts use detection mode.
Register new platform hosts in the [platform Ingress](../gateway/bunkerweb-platform-ingress.yaml)
when adding their HTTPRoutes.

`test.alumni.scg.skku.ac.kr` and `api.test.alumni.scg.skku.ac.kr` disable Bad
Behavior automatic IP bans and use a request rate limit of `100r/s` for
interactive testing. The application chart adds the service-specific Ingress
annotations. Existing bans must be removed separately with `bwcli unban`.

The Ingresses reuse the TLS Secrets issued by cert-manager. BunkerWeb watches
TLS Secret changes and verifies the origin certificate using the request hostname
as SNI. An `external: true` route continues to accept HTTP from its external
TLS terminator. The edge handles HTTP and HTTPS; plan a separate transport path
if a TLS passthrough route is added in the future.

The controller watches Ingresses across application namespaces and requires
cluster-wide Secret read permissions to consume and refresh certificates. The
Git source overrides the chart's `bunkerweb` ClusterRole to limit writes to
Ingress status. Argo CD reports the intentional `RepeatedResourceWarning` for
that role. Restrict access to the BunkerWeb namespace and its MariaDB volume
because the controller stores TLS material in its configuration database.
External Secrets Operator generates the API token and storage passwords once.
Back up `bunkerweb-credentials` with the database before rebuilding the namespace.

Argo CD considers a BunkerWeb-class Ingress healthy once the resource exists.
The controller uses host ports and its ClusterIP Service does not publish a
load-balancer address in Ingress status. Check the BunkerWeb DaemonSet and the
HTTPS endpoint to confirm that the route is serving traffic.

## Web UI

The management UI is served at `https://bunkerweb.platform.scg.sh` through the
platform BunkerWeb Ingress and the internal Envoy Gateway. The route's
`bunkerweb-ui-access` SecurityPolicy limits access to `115.145.0.0/16`.
The origin uses the client address forwarded by BunkerWeb through the existing
trusted-proxy policy. The UI Pod accepts traffic only from the Envoy Pods.

Create `platform/bunkerweb/ui` in Vault's `kv` engine with `admin-username` and
`admin-password`. External Secrets copies those keys into the
`bunkerweb-ui-credentials` Secret in the `bunkerweb` namespace. The account is
seeded on first startup; later account changes use the UI and must also be
recorded in Vault. Two-factor authentication is optional. Session signing and
encryption keys persist in the
`bunkerweb-ui-data` PVC mounted at `/data`.

The UI Deployment and Service are managed in `manifests/ui.yaml`. The chart's
bundled UI stays disabled because it requires UI keys in the shared immutable
infrastructure Secret and does not mount persistent UI state. The UI reuses the
existing database, Redis, and management API credentials through Secret
references. Its API access is allowed by the proxy NetworkPolicy.

Use the Bans page to remove a current IP ban. Settings managed through Ingress
annotations remain controlled by Git and can be read-only in the UI.

### Before merging

A Vault platform operator must apply the dedicated read policy and Kubernetes
authentication role. These allow only the
`bunkerweb/bunkerweb-ui-vault-auth` ServiceAccount to read
`kv/data/platform/bunkerweb/ui`.

```bash
export VAULT_ADDR=https://vault.platform.scg.sh
vault login -method=oidc role=github
vault policy write bunkerweb-ui argocd/platform/vault/policies/bunkerweb-ui.hcl
vault write auth/kubernetes/role/bunkerweb-ui \
  bound_service_account_names=bunkerweb-ui-vault-auth \
  bound_service_account_namespaces=bunkerweb \
  audience=vault token_policies=bunkerweb-ui \
  token_no_default_policy=true token_ttl=1h token_max_ttl=8h
```

The bootstrap script records the same configuration for fresh clusters. The
existing cluster's initial root token was revoked, so rerunning
`k initialize vault` does not apply this policy or role.

After merging, verify that the SecretStore and ExternalSecret are Ready, the UI
Deployment is available, and the HTTPRoute and SecurityPolicy are accepted.
From an allowed source, open the UI and sign in with the Vault credentials.
From a source outside `115.145.0.0/16`, verify that access is denied. Confirm that
the IP reported by the application is the original client address before
depending on the UI session's IP binding.

## Public cutover

Merging the introduction of this configuration hands public ports 80 and 443
from host-networked Envoy to BunkerWeb during reconciliation. Schedule the merge
for a maintenance window. The Applications reconcile independently and requests
may fail during the handoff.

After reconciliation, confirm that the BunkerWeb DaemonSet is ready and that
representative public hosts, including Alumni, serve valid certificates and reach
their Envoy backends. Verify the testing, preview, and production CIDR policies
from allowed and denied networks and confirm that the internal Envoy listener
rejects connections from unrelated Pods. Validate E2S separately before changing
the DNS target.

To roll back the initial cutover, revert the BunkerWeb change set in Git. Check
that BunkerWeb's host-port mappings are removed and that Envoy is serving HTTPS
on SCC again.
