# Bindizr

This Argo CD Application deploys [Bindizr](https://github.com/kweonminsung/bindizr),
a database-backed DNS control plane, with two BIND 9 secondaries and the
Bindizr web UI in the `bindizr` namespace. The chart is the published OCI
release `docker.io/kweonminsung/bindizr-chart`; `values.yaml` holds only the
cluster-specific overrides and `manifests/` the namespace, Vault integration,
load balancer address, and public route.

## What runs

| Workload | Role | Service |
| --- | --- | --- |
| `bindizr` Deployment (2) | HTTP API on 8000, DNS primary on 53, MySQL-backed | `bindizr-api`, `bindizr-dns`, `bindizr` (LoadBalancer :5300) |
| `bindizr-bind9` StatefulSet (2) | Authoritative secondaries fed by catalog zone AXFR/IXFR | `bindizr-bind9` (LoadBalancer), `bindizr-bind9-headless` |
| `bindizr-ui` Deployment (1) | Web UI; relays API calls to `bindizr-api` in-cluster | `bindizr-ui` |

Each BIND pod keeps its transferred zones on a retained 1 GiB `local-data`
volume, which pins the pod to its node; required anti-affinity places the two
replicas on different nodes. A starting bindizr pod registers the BIND pods as
secondaries by their headless names; a BIND pod that restarts may be refused
for about a minute until bindizr re-resolves its address.

## DNS entry point

`bindizr-bind9` is a `LoadBalancer` Service. The cluster provisions no load
balancer addresses, so `manifests/lb-ip-pool.yaml` lets Cilium LB IPAM assign
it a node address (`115.145.172.17`). The node already owns the address, so no
L2 or BGP announcement is involved: Cilium matches `<address>:53` as a service
frontend and spreads queries over both BIND pods. Point the parent zone's NS
glue at the Service's `EXTERNAL-IP`. When a node address changes, update the
pool block here and the glue record together.

## The primary's listener: dynamic updates and outside secondaries

`manifests/bindizr-service.yaml` exposes the bindizr primary's own DNS
listener on the same address as BIND, port 5300 (TCP and UDP), through Cilium
LB IPAM address sharing. RFC 2136 dynamic updates and TSIG-signed AXFR/IXFR
from secondaries outside the cluster (`bindizr.dns.extraSecondaries`) go
there; BIND on port 53 is a secondary and refuses both. Inside the cluster the
listener is `bindizr-dns.bindizr.svc.cluster.local:53` (ClusterIP
`10.106.52.252`).

bindizr is a hidden primary: it answers SOA queries only from registered
secondaries or from a TSIG-signed query whose key's role holds `zone:transfer`
for the zone. certbot's `dns-rfc2136` plugin finds the zone with SOA queries
against the update server, so its key needs that grant and the queries must be
signed (`dns_rfc2136_sign_query`, certbot 2.6.0 or later):

```bash
bindizr role create acme --description "certbot DNS-01"
bindizr role grant acme --zone scg.skku.ac.kr --actions zone:transfer
bindizr role grant acme --zone scg.skku.ac.kr \
    --actions record:read,record:create,record:delete --pattern "_acme-challenge" --types TXT
bindizr tsig-key create acme-key --role acme     # the secret is shown here; tsig-key get shows it again
```

```ini
dns_rfc2136_server = 115.145.172.17
dns_rfc2136_port = 5300
dns_rfc2136_name = acme-key
dns_rfc2136_secret = <base64 secret from tsig-key create>
dns_rfc2136_algorithm = HMAC-SHA256
dns_rfc2136_sign_query = true
```

certbot accepts only an IP address as the server. One `_acme-challenge.<name>`
grant is needed per certificate name.

## Database

Bindizr uses the external MySQL server `mysql-scg.scg.skku.ac.kr:3306`,
database `dns_prod`. The connection URL is the only secret:

| Vault path | Key | Kubernetes Secret | Read by |
| --- | --- | --- | --- |
| `kv/platform/bindizr` | `DB_URL` | `bindizr/bindizr-db` | Deployment env `BINDIZR_DATABASE_URL` |

`DB_URL` is `mysql://<user>:<password>@mysql-scg.scg.skku.ac.kr:3306/dns_prod`
with the password percent-encoded. The namespaced `bindizr` SecretStore
authenticates as the `bindizr-vault-auth` ServiceAccount through the Vault
Kubernetes auth role `bindizr`, whose policy
([`../vault/policies/bindizr.hcl`](../vault/policies/bindizr.hcl)) reads only
that path. The role exists; `k initialize vault` recreates it on a fresh Vault.
Never commit or print the secret value.

## Access

The web UI is routed at `https://dns.platform.scg.sh` through the public
Gateway's `platform-https` listener (wildcard certificate and DNS record). The
HTTP API is not routed externally; the UI relays to `http://bindizr-api:8000`,
and operators reach the API with `kubectl -n bindizr port-forward svc/bindizr-api 8000`
or the `bindizr` CLI inside a bindizr pod. Every API endpoint except `/health`
and `/metrics` requires a bearer token:

```bash
kubectl exec -n bindizr deploy/bindizr -- bindizr token create admin --role admin
```

The UI stores its Bindizr URL, token, and admin account in the pod's own
SQLite file without a volume, so a restarted UI pod returns to its setup
screen. Because the UI holds an API token and is public, create its admin
account during setup.

## Pod security

The namespace enforces `baseline` (warning and auditing at `restricted`)
because the ISC BIND image runs `named` as root to bind port 53. The Bindizr
container itself satisfies `restricted`.
