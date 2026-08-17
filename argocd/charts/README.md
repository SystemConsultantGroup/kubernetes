# Helm charts

This directory contains Helm charts used by Argo CD. The current chart,
[`application/`](application/), renders managed application instances from
application metadata and immutable locks.

The chart is platform code, not a general-purpose application chart. Its values
are assembled by the ApplicationSets with an internal Argo CD context. A
change can affect every managed application.

Render the affected chart locally and inspect its Deployments, Services, routes,
and image locks before opening a pull request. Do not apply rendered output to
a live cluster for ordinary chart validation.
