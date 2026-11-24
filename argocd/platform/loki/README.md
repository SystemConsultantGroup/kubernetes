# Loki

This component stores application Pod logs for Grafana queries. It runs one
monolithic Loki replica with the TSDB v13 schema and filesystem storage. The
service is ClusterIP-only; Grafana queries it from the `monitoring` Namespace and
Alloy writes to it from the `alloy` Namespace.

Logs are retained for seven days. Loki requests a `40Gi` `local-data` volume and
retains its claim when the StatefulSet is scaled down or deleted. As with
Prometheus, this volume is node-local and unreplicated. Node loss can therefore
make logging unavailable or destroy retained logs. The PVC request is scheduling
metadata rather than a filesystem quota, so continue monitoring
`/var/mnt/data` capacity.

The lightweight deployment disables the gateway, caches, canary, and distributed
Loki components. The Pod uses the `RuntimeDefault` seccomp profile so that every
container satisfies the Namespace's restricted Pod Security policy. Network policy
accepts ingress only from Loki itself, Alloy, and monitoring. There is no public
route or application-facing Loki API.

Alloy's application-label filter is the data boundary: Loki authentication and
multi-tenancy are disabled because this is one internal application-log tenant.
Do not broaden the collector without reviewing what Grafana's application users
would be able to read. Applications must not write credentials, tokens, personal
data, or other secrets to stdout or stderr.

Validate chart rendering and the storage, retention, network, and exposure
invariants with:

```bash
nix flake check
```

After an authorized rollout, verify the PVC binding, Loki readiness, Alloy write
success, Grafana queries, and the rate at which the node's data filesystem grows.
