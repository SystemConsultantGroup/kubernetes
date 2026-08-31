[한국어](README.md) | English

# Application ingress policy chart

This platform chart renders one `CiliumClusterwideNetworkPolicy` for a managed
application's production domains. The `application-routing-policies`
ApplicationSet reads each `applications/*/meta.yaml` file and reconciles the
policy through the `platform` AppProject.

The public Gateway's base policy denies internet traffic by default. This chart
allows `world` traffic only when the HTTP host exactly matches a declared
production domain, on port 443 for platform-managed TLS or port 80 for a domain
marked `external: true`. Testing and preview hostnames are intentionally absent;
the base Gateway policy admits those hosts only from `115.145.150.0/24`.

This is platform enforcement code, not an application-owner interface. Keep its
domain interpretation aligned with the routing logic in
[`../application/templates/routing.yaml`](../application/templates/routing.yaml).
