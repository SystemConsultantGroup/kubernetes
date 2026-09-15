# GitHub login latency investigation

Date: 2026-09-15

## Status

This is a read-only investigation note. No repository or cluster configuration
was changed, and no local cluster credentials or encrypted secret values were
read.

The most likely shared source of login latency is the GitHub connector in the
Argo CD-bundled Dex instance. Its callback path performs several dependent
GitHub API requests serially, including a complete paginated enumeration of the
user's teams before filtering the result to the two configured teams.

This conclusion has medium-high confidence, but it is not yet confirmed by a
real authenticated callback trace. Browser timing, Dex logs, and cluster-side
network observations are still required to attribute the observed delay to a
specific request.

## Shared authentication path

Argo CD, Vault, and Grafana all use the same Dex GitHub connector:

```text
Argo CD --+
Vault ----+--> Argo CD-bundled Dex --> GitHub OAuth and REST API
Grafana --+
```

The downstream clients do not share sessions or client identities. Vault and
Grafana each have a distinct Dex static client and secret. They nevertheless
share the upstream GitHub connector and therefore share its callback work and
network path.

The relevant desired state is:

- `argocd/values.yaml` defines one GitHub connector restricted to the
  `SystemConsultantGroup` organization and the `active` and `platform` teams;
- Argo CD authorization consumes the `groups` claim;
- `scripts/k.commands/initialize/vault.sh` configures Vault to request and map
  the `groups` claim from Dex; and
- `argocd/platform/monitoring/values.yaml` configures Grafana to request the
  `groups` scope and derive access and roles from the same two teams.

Consequently, group lookup is part of the authorization model rather than an
unused optional claim.

## Primary finding: serial GitHub API work in Dex

The repository pins Argo CD chart `10.2.2` in `state.yaml` and
`argocd/platform/argocd/application.yaml`. The repository does not override the
chart's Dex image, so the chart default, Dex `v2.45.1`, applies.

In Dex `v2.45.1`, a successful GitHub authorization callback performs the
following work in order:

1. exchange the OAuth authorization code for an access token;
1. request `GET /user`;
1. request `GET /user/emails` when the user has no public GitHub email;
1. request `GET /orgs/{org}/members/{user}` to verify organization membership;
1. request `GET /user/teams`; and
1. follow every team pagination link serially before filtering the returned
   teams against `active` and `platform`.

Upstream source references:

- [callback processing](https://github.com/dexidp/dex/blob/v2.45.1/connector/github/github.go#L217-L277);
- [configured organization and team processing](https://github.com/dexidp/dex/blob/v2.45.1/connector/github/github.go#L343-L375);
- [user and optional email lookup](https://github.com/dexidp/dex/blob/v2.45.1/connector/github/github.go#L527-L543); and
- [complete `/user/teams` enumeration](https://github.com/dexidp/dex/blob/v2.45.1/connector/github/github.go#L692-L719).

A callback therefore requires at least four serial GitHub round trips after the
browser returns from authorization: token exchange, user lookup, organization
membership lookup, and team lookup. A private GitHub email adds another round
trip. Team pagination adds one round trip per additional page.

Dex does not set `per_page` on `/user/teams`. GitHub documents a default page
size of 30 and a maximum of 100 for the "List teams for the authenticated user"
endpoint. A user belonging to more than 30 teams across GitHub organizations
therefore requires additional serial requests. The configured list containing
only two relevant teams does not reduce the API result before retrieval; Dex
filters the complete response locally.

This predicts higher latency for users who:

- do not expose a public primary email on GitHub;
- belong to many GitHub organizations; or
- belong to many teams across those organizations.

Removing only the configured team names is not a valid optimization for this
Dex version. `groupsForOrgs` invokes `teamsForOrg` before checking whether the
organization has a team filter, so an organization-only entry still enumerates
`/user/teams`. Removing group processing altogether would also break the
current Argo CD, Vault, and Grafana authorization mappings.

## Gateway and DNS assessment

A Gateway or DNS failure is a credible alternative because the repository
records an earlier Vault OIDC incident in
`working/E2S_VAULT_OIDC_DNS_FIX.md`. Public DNS previously advertised both SCC
and E2S while the E2S Gateway path returned a `503` connection timeout. A
server-side Vault token exchange could therefore select the failing address.

The current desired state mitigates that incident by pinning the public Gateway
DNS target to SCC at `115.145.134.232` in
`argocd/platform/gateway/gateway.yaml`.

At investigation time, public DNS returned only that address for Argo CD, Vault,
and Grafana. Non-authenticated external timing samples produced these results:

| Request | Observed time |
| --- | ---: |
| Dex OIDC discovery | approximately 11-12 ms |
| Argo CD `/auth/login` | approximately 11-12 ms |
| GitHub authorization endpoint | approximately 213-232 ms |
| Grafana login redirects up to the GitHub login page | approximately 509 ms |

These samples indicate that DNS, TLS, the public Gateway, and Dex discovery were
fast before authentication at the time of the investigation. They do not
measure the authenticated GitHub-to-Dex callback or traffic originating in a
cluster pod. The likely delay therefore remains the callback path, but the
Gateway hypothesis is not fully excluded.

A Gateway or DNS regression should become the primary hypothesis again if any
of the following are observed:

- intermittent `503` responses or connection timeouts;
- different results when targeting SCC and E2S directly;
- fast Argo CD login but slow Vault and Grafana login; or
- a delay isolated to the downstream OIDC token exchange rather than the Dex
  GitHub callback.

Vault and Grafana also use the public Argo CD hostname for server-side OIDC
requests. This adds a cluster-to-public-Gateway-to-Argo-CD path for those two
services, although it does not explain a delay shared equally with Argo CD.

## Other hypotheses

### Dex-to-GitHub egress or GitHub API latency

Slow DNS resolution, network egress, GitHub rate limiting, or GitHub API latency
would multiply the cost of Dex's serial request pattern. No cluster-side egress
timing or rate-limit response headers were collected, so this remains a
plausible contributing factor.

### Dex capacity

A single constrained Dex instance or CPU throttling could add queueing and
processing latency. The repository contains no live utilization or throttling
evidence supporting this explanation, so it currently has low confidence.

### Grafana bandwidth limits

Grafana's egress bandwidth setting is unlikely to explain the overall issue.
OAuth payloads are small, and Argo CD and Vault exhibit the same shared
authentication path.

## Observability gap

The current evidence cannot separate the duration of:

- OAuth token exchange;
- `/user` and optional `/user/emails` requests;
- organization membership verification;
- `/user/teams` pages;
- downstream Vault or Grafana token exchange; and
- local Dex scheduling or CPU delay.

The chart's Dex metrics are disabled by default, and the repository does not
enable them. There is also no connector-level timing instrumentation in the
repository. Static configuration is therefore sufficient to identify the
likely structural bottleneck but not to prove which call dominates production
latency.

## Recommended verification

Before changing authentication policy, capture one complete login for each of
Argo CD, Vault, and Grafana:

1. record redirect timestamps in a browser HAR;
1. identify when GitHub returns to the Dex callback and when that callback
   completes;
1. correlate the same interval with Dex logs;
1. distinguish the upstream GitHub callback from the downstream Vault or
   Grafana token exchange; and
1. compare a user with few team memberships to a user with many memberships.

Interpret the result as follows:

| Observation | Most likely area |
| --- | --- |
| GitHub-to-Dex callback is slow | Dex GitHub API sequence |
| Only Vault or Grafana token exchange is slow | public Gateway hairpin or internal DNS |
| Login is slow before reaching GitHub | browser, Gateway, or initial Dex route |
| Intermittent `503` or connect timeout | Gateway or DNS regression |
| Delay grows with total team membership | `/user/teams` pagination |

Collect timings without logging authorization codes, access tokens, cookies, or
other credentials.

## Recommended remediation order

1. **Measure an authenticated callback.** Confirm which serial operation is
   slow before changing the authorization model.
1. **Revalidate DNS and Gateway behavior.** Confirm that DNS still returns only
   SCC and that direct node behavior is consistent. Do not remove the existing
   SCC pin without completing the separate E2S ingress validation.
1. **Avoid complete team enumeration.** If the primary finding is confirmed,
   evaluate a reviewed connector change that checks only configured team
   memberships, performs independent checks concurrently, or caches membership
   claims for a short bounded period.
1. **Reduce repeated login frequency.** Vault tokens are renewable with a
   one-hour TTL and an eight-hour maximum TTL; operators should renew an active
   token instead of repeating browser login. Review Argo CD and Grafana session
   lifetimes against security requirements as a separate mitigation.
1. **Optimize internal OIDC routing.** Consider split-horizon DNS or an
   equivalent internal route for Vault and Grafana while preserving the public
   issuer hostname and TLS validation.
1. **Upgrade only with source evidence.** A Dex or Argo CD version upgrade
   should not be assumed to fix this issue. Dex `master` still follows the same
   broad team-enumeration pattern at the time of this investigation; inspect the
   exact target version before upgrading.

A custom connector or identity broker must preserve the current distinction
between `SystemConsultantGroup:active` and `SystemConsultantGroup:platform`.
Performance should not be improved by weakening the authorization boundary.

## Current assessment

| Candidate | Confidence | Assessment |
| --- | --- | --- |
| Serial Dex GitHub API calls and team pagination | Medium-high | Best explanation for latency shared by all three services |
| Dex-to-GitHub egress or GitHub API latency | Medium | Likely multiplier of the serial request cost |
| Gateway or DNS regression | Medium-low | Proven historical issue, but current public path and DNS were healthy |
| Dex CPU or replica capacity | Low | No supporting utilization evidence |
| Grafana bandwidth limit | Low | Does not explain the shared behavior |

No cluster mutation or repository validation suite was required because this
investigation only added documentation. Durable authentication architecture or
operating procedures resulting from a future fix should be moved to the nearest
component README rather than maintained only in this working note.
