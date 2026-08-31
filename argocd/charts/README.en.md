[한국어](README.md) | English

# Helm charts

This directory contains Helm charts used by Argo CD.
[`application/`](application/README.en.md) renders managed application instances
from metadata, immutable locks, and an internal instance context.
[`application-ingress-policy/`](application-ingress-policy/README.en.md) renders
the corresponding public production-host policy.

The application chart owns the managed application schema, resource naming,
workload rendering, and Gateway routing behavior. The ingress-policy chart keeps
production public while the Gateway policy restricts testing and preview. Application owners should
start with the
[`applications/` workflow](../../applications/README.en.md); the
[chart README](application/README.en.md) is the exhaustive field and rendering
reference for advanced configuration and platform changes.

The chart is platform code rather than a general-purpose application chart.
A change can affect every managed application.
Render affected values locally and inspect Deployments, Services, routes,
certificates, namespaces, and image locks before opening a pull request.
Do not apply rendered output to a live cluster for ordinary chart validation.
