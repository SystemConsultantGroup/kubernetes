# Per-workload CIDR allow/deny filtering

Investigation note for source-IP (CIDR) based request filtering on managed
application workloads. This note records the current platform state, the
options evaluated, the recommended approach, and the implementation plan.
Move durable contracts (final field names, invariants, user workflow) into
`argocd/charts/application/README.md` and `applications/README.md` once
implemented.

> **Status: implemented on `feat-cidr-filtering`.** Resolved during
> implementation: cluster-internal traffic is always allowed (no
> `allowClusterInternal` toggle); CIDRs must be octet-aligned `/8`, `/16`,
> `/24` or single IPs `/32` (enforced by the schema pattern, plus a
> render-time `fail` backstop); the platform default list lives in both
> managed-instance ApplicationSets as `_context.access.defaultCIDRs`
> (`115.145.0.0/16`); testing/preview render fail-closed (missing platform
> CIDRs still produce a deny-all policy); repository checks inject the
> ApplicationSet CIDRs into renders and assert generated policies with
> synthetic values.

## Goal

- Production workloads: unrestricted by default (fe, be). A workload that
  declares `allowCIDRs` accepts requests only from those CIDRs (whitelist).
- Testing and preview instances: always restricted to a platform-defined
  CIDR list, regardless of what the application declares.
- Filtering is platform-enforced: application developers cannot bypass it
  by editing their application files.

## 1. Current state

- Ingress is a single Cilium Gateway `public` in `gateway-system` with three
  HTTPS listeners (`*.platform.scg.sh`, `*.testing.scg.sh`, `*.preview.scg.sh`).
  The chart renders a **ListenerSet per external workload hostname** parented
  to that Gateway, plus per-instance HTTPRoutes
  (`argocd/charts/application/templates/routing.yaml`).
- Listener exposure is via Cilium **host-network mode** on nodes labeled
  `gateway.scg.sh/listener: "true"` (`argocd/platform/cilium/values.yaml`),
  pinned to SCC by the `external-dns.alpha.kubernetes.io/target` annotation
  for the E2S attachment rehearsal. External clients enter through the node
  IPs in `state.yaml` (SCC `115.145.134.232`, E2S `115.145.172.19`).
- The chart generates no NetworkPolicy today. Workload pods are labeled
  `app.kubernetes.io/name` + `app.kubernetes.io/instance`, so they are easy
  targets for a generated policy.
- Instance type (`production` / `testing` / `preview-...`) already reaches
  the chart through `_context` injected by the ApplicationSets, so the chart
  can behave differently per instance type without new plumbing.
- Standard Gateway API `HTTPRoute` has **no source-IP match type** (only
  hostname, path, header, query, method). Cilium's NGINX-annotation migration
  table marks the `whitelist-source-range` equivalent as "Not yet supported"
  and recommends network policy instead.

### Critical platform fact: where filtering can and cannot happen

Cilium routes all Gateway traffic through a per-node Envoy proxy:

- The Envoy is a Cilium NetworkPolicy enforcement point for ingress traffic.
- Backend pods see the **gateway Envoy's IP as the TCP peer**, not the
  client. The client IP is preserved at L7 via `X-Forwarded-For` and
  `X-Envoy-External-Address` headers (set by Envoy itself).
- Therefore an L3 `fromCIDR` / `CiliumNetworkPolicy` rule **on the backend
  pod cannot allowlist external clients** arriving through the Gateway
  (upstream issues
  [#34786](https://github.com/cilium/cilium/issues/34786) and
  [#43556](https://github.com/cilium/cilium/issues/43556), closed as a
  feature gap). This is the trap most Cilium Gateway API users hit first.
- The `world → ingress` policy stage (first enforcement point) can use CIDR
  rules, but it applies to the shared `ingress` identity of the whole
  Gateway — it cannot distinguish routes, hostnames, or workloads.
- Per-route/per-workload client-IP authorization must therefore happen
  either in **L7 policy** (header matching done by the Envoy doing the
  policy lookup for the backend) or **at an added proxy layer**.

## 2. Options evaluated

| # | Option | Per-workload | Security boundary | Effort | Verdict |
| --- | --- | --- | --- | --- | --- |
| A | CNP on the backend pod, L3 `fromCIDR` | yes (chart-generated) | **none — does not work** through the Gateway (Envoy re-originates connections) | low | Rejected; documented as the trap to avoid |
| B | CNP on the backend pod, L7 `hdrMatches` on `X-Envoy-External-Address` | yes (chart-generated) | enforced at the gateway-side Envoy before proxying; spoof-resistant header | medium | **Recommended** |
| C | Platform-wide `world → ingress` CIDR policy | no (whole Gateway) | strong L3 | low | Useful only for "restrict everything", not per-workload |
| D | Raw `CiliumEnvoyConfig` with Envoy RBAC (`source_ip` permissions) per listener | per-listener | strong | high (fragile raw config alongside chart routes) | Fallback for strict-boundary needs; track upstream first |
| E | Sidecar / dedicated auth-proxy (nginx allow/deny on real IP, Traefik ipWhiteList middleware) per restricted workload | yes | strong | high (new component per workload) | Rejected for now; revisit if B proves insufficient |
| F | Application-level middleware reading `X-Forwarded-For` | yes (per app) | weak (platform cannot enforce) | low per app | Rejected — violates "platform-enforced" goal |
| G | Wait for upstream Gateway API / Cilium native support | — | — | — | Not actionable now; track issues below |

Notes on B:

- Cilium CNP L7 rules on the backend pod are evaluated by the per-node
  (gateway-side) Envoy when traffic ingresses via the Gateway, so a failed
  match is rejected with `403` before the request reaches the workload.
- Matching `X-Envoy-External-Address` (set by Envoy to the real client IP)
  avoids the `X-Forwarded-For` spoofing problem, where a client may seed its
  own value.
- CNP L7 header matches support `exact` / `prefix` / `suffix` / `regex`.
  There is no CIDR matcher, so CIDRs are translated:
  - octet-aligned CIDRs (`/8`, `/16`, `/24`) → `prefix` match (e.g.
    `115.145.0.0/16` → `value: "115.145."`);
  - single IPs (`/32`) → `exact` match;
  - non-octet-aligned CIDRs → RE2 `regex` (manual, rare case).
- Cilium maintainers note header-based allowlists are weaker than a true L3
  boundary for long-lived/streaming connections; acceptable here because
  these are ordinary HTTP workloads and the header is Envoy-set, not
  client-set.

Upstream to track (may become the long-term primitive):

- [#43556](https://github.com/cilium/cilium/issues/43556) — per-application
  IP allowlisting with Gateway API (closed as feature gap).
- [#45951](https://github.com/cilium/cilium/issues/45951) / PR #46479 —
  Gateway API `ExtensionRef` via `CiliumEnvoyExtProcFilter` (Cilium 1.20+);
  a future hook point for IP filtering without raw `CiliumEnvoyConfig`.
- [NGINX annotation migration table](https://docs.cilium.io/en/latest/network/servicemesh/ingress-to-gateway/nginx-annotations-migration/)
  — canonical "not yet supported" reference.

## 3. Recommendation (best practice for this repo)

Chart-generated `CiliumNetworkPolicy` with L7 `hdrMatches` on
`X-Envoy-External-Address` (Option B), for both feature areas:

1. **Production allowlist**: `applications/<app>/meta.yaml` gains an optional
   `http.allowCIDRs` list per workload. When present, the chart renders a
   CNP into the instance namespace selecting that workload's pods.
   Absent = no policy = always allowed (fe/be unchanged).
1. **Testing/preview lockdown**: the ApplicationSets inject platform-owned
   default CIDRs through `_context` (e.g. `_context.access.defaultCIDRs`).
   The chart renders the same CNP for every workload in testing/preview
   instances. Applications cannot opt out; platform review of the
   ApplicationSet values is the authorization boundary, consistent with
   existing contracts.

Whitelist semantics come from Cilium's policy model: once a policy selects
an endpoint, unlisted ingress is denied. The gateway Envoy does the matching,
so denial happens before the request is proxied upstream.

## 4. Implementation plan

1. **Chart template** — new `templates/network-policy.yaml`:
   - condition: any workload (of this instance) has effective `allowCIDRs`
     = workload `http.allowCIDRs` (production) or `_context.access.defaultCIDRs`
     (testing/preview);

   - `endpointSelector`: `app.kubernetes.io/name` + `app.kubernetes.io/instance`;

   - one `ingress` rule per allowed CIDR:

     ```yaml
     apiVersion: cilium.io/v2
     kind: CiliumNetworkPolicy
     spec:
       endpointSelector:
         matchLabels:
           app.kubernetes.io/name: manage
           app.kubernetes.io/instance: example-production
       ingress:
         - fromEntities:
             - ingress            # the gateway Envoy is the only external path
           toPorts:
             - ports:
                 - port: "8080"
                   protocol: TCP
               rules:
                 http:
                   - hdrMatches:
                       - name: X-Envoy-External-Address
                         match: prefix   # octet-aligned /16
                         value: "115.145."
     ```

   - multiple CIDRs = multiple HTTP rules (OR semantics); `hdrMatches` inside
     one rule are ANDed, one match per rule here;

   - cluster-internal traffic is always allowed; a second ingress rule from
     the `cluster` entity permits other workloads to call a restricted
     workload east-west (fe/be → manage).
1. **Schema + ApplicationSet**:
   - extend `argocd/charts/application/values.schema.source.json` with
     `http.allowCIDRs` (IPv4 CIDR strings) and `http.allowClusterInternal`;
   - extend the two ApplicationSets' `values: |` block with
     `_context.access.defaultCIDRs` sourced from platform config;
   - regenerate `values.schema.json` with
     `k render application-schemas` (needs network) and verify with
     `k render application-schemas --check`.
1. **CIDR translation helper** — support octet-aligned `/8`, `/16`, `/24`
   via `prefix`, `/32` via `exact`; reject anything else in the repository
   checks with a pointer to the manual regex escape hatch. Keep this rule
   visible in the chart README. (`ponytail:` no Helm-side IPv4 math — widen
   to full RE2 CIDR→regex generation only when a real non-octet-aligned
   requirement appears.)
1. **Repository checks** — extend `scripts/checks/repository.sh`:
   - CIDR strings are valid IPv4 CIDR and octet-aligned;
   - `allowCIDRs` never appears in instance lock files (locks stay
     `source` + `image` only);
   - names/lengths unchanged.
1. **Local validation** — `helm template` renders for production (no CNP),
   production with `allowCIDRs` (CNP present), testing/preview (CNP with
   platform defaults), plus `nix fmt -- --ci .` and `nix flake check`.
1. **Cluster validation** — never use production as the test bed. Validate
   with a small throwaway preview instance of `applications/example` and a
   `hubble observe` / curl matrix (allowed CIDR, disallowed CIDR, spoofed
   `X-Forwarded-For` with mismatched `X-Envoy-External-Address`) before
   merging the chart change. Removing an `allowCIDRs` entry must re-open
   access (policy diff) — verify Argo CD sync behavior.
1. **Documentation** — chart README (new "CIDR filtering" section: field
   reference, octet-alignment rule, east-west note, security caveats),
   `applications/README.md` (workflow for app owners), and the directory
   READMEs — English source first, Korean published in the same change.
1. **Follow-up decisions (explicitly deferred)**:
   - IPv6 sources (SCC/E2S are IPv4 today);
   - non-HTTP workloads (TLS passthrough cannot be filtered at L7);
   - migration to a native Cilium primitive if the tracked upstream issues
     land one — the CNP then becomes redundant and should be removed in a
     single chart change.

## References

- Cilium Gateway API docs — network policy behavior, `ingress` identity,
  source IP visibility (`X-Forwarded-For`, `X-Envoy-External-Address`):
  <https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/gateway-api/>
- Cilium L3 policies (`fromCIDR` semantics): <https://docs.cilium.io/en/stable/security/policy/layer3/>
- Upstream limitations: issues #34786, #32755, #43556, #43942 (linked above).
- Repo layout facts: `argocd/charts/application/templates/routing.yaml`,
  `argocd/application-sets/instances.yaml`, `argocd/platform/cilium/values.yaml`.
