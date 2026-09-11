# Monitoring

This component deploys `kube-prometheus-stack` for cluster and node metrics.
Grafana is available to application developers and platform engineers at
<https://grafana.platform.scg.sh>; Prometheus and Alertmanager have no public
route and remain ClusterIP-only.

## Metrics and capacity

Prometheus scrapes every 60 seconds and evaluates rules every 60 seconds. The
chart's kubelet/cAdvisor integration, kube-state-metrics, and node exporter
collect CPU, memory, network, and filesystem metrics from both Talos nodes.
Default node dashboards, recording rules, and alerts are enabled. A
Git-managed `Node Overview` dashboard is also provisioned and configured as
Grafana's home dashboard. It shows readiness plus CPU, memory, network, and
`/var/mnt/data` filesystem metrics for every node in one view. Additional rules
warn on sustained CPU or memory use above 85%, `eno1` receive or transmit use
above 70%, and `/var/mnt/data` use above 75%.

Talos does not expose etcd, controller-manager, or scheduler metrics through the
endpoints assumed by this chart, and this cluster has no kube-proxy. Those four
scrape integrations and their unmatched alert rules are disabled rather than
left permanently unhealthy. Kubernetes API, kubelet, CoreDNS, node exporter,
and kube-state-metrics monitoring remain enabled.

The `monitoring` Namespace explicitly permits privileged Pod Security because
node exporter requires host networking, the host PID namespace, and a read-only
host root mount. Restricted-policy audit and warning labels remain enabled. Only
platform-owned resources may target this Namespace; do not place application
workloads in it.

Prometheus runs as one replica with these storage bounds:

| Setting | Value |
| --- | --- |
| StorageClass | `local-data` |
| PVC request | `50Gi` |
| Time retention | `7d` |
| Size retention | `40GB` |

The PVC is node-local, unreplicated, and retained after claim deletion. A
Prometheus Pod cannot attach that volume from the other node, so node loss can
cause monitoring downtime or data loss. The PVC request is scheduling capacity,
not a filesystem quota; Prometheus size retention provides the practical bound,
and WAL/compaction can temporarily exceed it.

Cilium Bandwidth Manager enforces the Prometheus and Grafana Pod annotations:
ingress is limited to `10M` and egress to `5M` for each Pod. The Prometheus
limits cover scrapes and datasource queries; the Grafana limits bound dashboard
traffic. They must be checked after rollout for missed scrapes or slow
dashboards. Node exporter uses the host network as required for node metrics, so
its small 60-second scrape responses are bounded indirectly by Prometheus
receiver backpressure rather than a per-Pod annotation.

## Authentication

Grafana uses Argo CD's existing Dex and GitHub connector. Authorization is
deny-by-default:

- `SystemConsultantGroup:platform` receives Grafana organization `Admin`;
- `SystemConsultantGroup:active` receives `Viewer`; and
- users in neither group are denied.

The platform rule is evaluated first because platform members can also belong
to `active`. Anonymous access, the login form, and HTTP basic authentication
are disabled. The provisioned Node Overview dashboard is read-only in Grafana;
changes must be made to its JSON source in Git. The dedicated Grafana Dex client
secret and stable chart administrator password are read from encrypted
`secrets/bootstrap.yaml` during a fresh
`k install argocd`, or by `k initialize monitoring` on an existing cluster. The
command copies them through standard input to `argocd/argocd-grafana-oidc`,
`monitoring/grafana-oidc`, and `monitoring/grafana-admin`; they are never stored
in chart values. The stable administrator Secret prevents Helm's generated
password from changing on every GitOps render. The login form and basic
authentication remain disabled, so routine access still requires GitHub.

Before bootstrapping or rotating these values, set distinct random
`GRAFANA_OIDC_CLIENT_SECRET` and `GRAFANA_ADMIN_PASSWORD` values with
`k secrets edit bootstrap`, commit only the SOPS-encrypted file, and run the
explicitly authorized initialization operation before Argo CD reconciles the
Dex and Grafana resources. Changing encrypted values alone does not update
existing Kubernetes Secrets.

## Scope

This rollout is metrics-first. It does **not** deploy Loki, Grafana Alloy,
`PodLogs`, or any production log collection. Logging requires a separate design
and approval after the metrics platform has been measured.

## Validation and operations

Local repository checks render the pinned chart and enforce retention, storage,
intervals, bandwidth annotations, internal Prometheus/Alertmanager exposure,
Grafana routing, OAuth role mapping, the provisioned Node Overview dashboard,
custom capacity alerts, and the expected node scrape integrations. They do not
contact or mutate the live cluster.

Alerts are initially visible in Prometheus and Grafana only. Delivering them to
email, Slack, or another external receiver requires a separate destination and
Secret review.

After a separately authorized rollout, operators must verify Bandwidth Manager
on both nodes, healthy Prometheus targets, the `k8s` and `e2s` node metric series,
PVC binding, all three Grafana authorization outcomes, and the absence of public
Prometheus or Alertmanager routes.
