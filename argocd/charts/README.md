# Helm charts

This directory contains Helm charts used by Argo CD. The current chart is
[`application/`](application/), the shared renderer for managed application
instances.

The chart is not a general-purpose application chart. Its values are assembled
from application metadata, an immutable instance lock, and an Argo CD context
by the ApplicationSets.

Changes here can affect every managed application. Render the affected chart
locally and inspect the resulting Kubernetes resources before opening a pull
request. Do not apply test output to a live cluster as part of ordinary chart
work.
