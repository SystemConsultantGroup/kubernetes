# Alumni platform access

This is the existing production instance on the new cluster, using `alumni_prod`
and the `skku-alumni-prod` bucket. The `test` hostnames do not create an isolated
test database or migrate legacy production data.

| Workload | HTTPS hostname |
| --- | --- |
| user | test.alumni.scg.skku.ac.kr |
| admin | admin.test.alumni.scg.skku.ac.kr |
| be | api.test.alumni.scg.skku.ac.kr |

## Rollout order

1. Merge the backend platform-profile PR and wait for the backend image lock to
   update in `instances/production.yaml`.
1. Set the frontend repository variable `PLATFORM_NEXT_PUBLIC_API_BASE_URL` to
   `https://api.test.alumni.scg.skku.ac.kr`, merge the frontend cookie-forwarding
   PR, and wait for both frontend image locks to update. Manual bootstrap builds
   do not update an existing application's locks.
1. Merge this infrastructure change. The backend uses `prod,platform` and the
   user server forwards only the matching `platform_member_*` authentication
   cookies. Existing `prod` and `dev` profiles remain available for legacy CD.
1. Complete DNS and certificate validation, then test member/admin login, member
   lists rendered on the server, password reset links, and image uploads.

The chart creates three ListenerSets, HTTPRoutes, and Certificates. Each route
targets its corresponding Service on port 80. The Gateway terminates TLS and
does not forward requests to the legacy cluster.

## DNS and TLS

The DNS owner must register all three hostnames against the public Gateway.
The current repository pins its public DNS target to `115.145.134.232`; confirm
the live target before registering records:

```sh
kubectl --context admin@scg get gateway public -n gateway-system \
  -o jsonpath='{.metadata.annotations.external-dns\.alpha\.kubernetes\.io/target}{"\n"}'
```

ExternalDNS manages `scg.sh` only; it does not register these `scg.skku.ac.kr`
records. DNS edits may replace an existing legacy development endpoint, so
coordinate record ownership before changing them.

Certificates use the existing `zerossl-cloudflare` ClusterIssuer, which performs
DNS-01 validation through Cloudflare. A/AAAA records alone do not complete that
validation. The DNS/platform owner must ensure the issuer can manage the required
challenge records for all three names, or arrange an appropriate certificate
issuer change separately. This PR does not provision DNS credentials, change the
shared issuer, or assume an existing wildcard certificate covers the names.

Check readiness after reconciliation:

```sh
kubectl --context admin@scg get listenersets,httproutes,certificates -n alumni-production
kubectl --context admin@scg get certificateRequests,orders,challenges -n alumni-production
```

Proceed with HTTPS browser verification only after Certificates are Ready and
routes/listeners are accepted. A successful Pod startup does not verify DNS or
certificate issuance.
