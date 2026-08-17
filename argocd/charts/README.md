# Helm charts

This directory contains Helm charts used by Argo CD. The current chart,
[`application/`](application/), renders managed application instances from
metadata, immutable locks, and an internal instance context.

The application chart owns the managed application schema, resource naming,
workload rendering, and Gateway routing behavior. Read its
[`README.md`](application/README.md) before changing application metadata or
chart templates.

The chart is platform code rather than a general-purpose application chart. A
change can affect every managed application. Render affected values locally
and inspect Deployments, Services, routes, certificates, namespaces, and image
locks before opening a pull request. Do not apply rendered output to a live
cluster for ordinary chart validation.
