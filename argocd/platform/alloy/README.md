# Alloy

This component runs Grafana Alloy as a DaemonSet and sends application container
stdout and stderr to the internal Loki service. Each Alloy Pod discovers only
Pods assigned to its own node through the Kubernetes API; it does not mount host
log directories or require privileged Pod Security.

The collector keeps only Pods carrying both of these labels:

```yaml
app.kubernetes.io/part-of: <application>
platform.scg.sh/instance-type: production|testing|preview|custom
```

The managed application chart already supplies both labels. Custom Kustomize
applications opt in by adding them to their Pod templates. Unlabeled platform
and system Pods are excluded.

Loki streams receive bounded metadata labels: `cluster`, `namespace`,
`application`, `instance_type`, `workload`, `pod`, `container`, and
`container_runtime`. Do not promote request IDs, user IDs, image digests, or
other unbounded values to Loki labels. Structured application logs remain in the
log line and can be parsed at query time.

The chart's broad default RBAC is disabled. Git-managed RBAC grants only the
cluster-wide Pod discovery and log access required by the collector. Alloy's
service is ClusterIP-only and exists for Prometheus metrics; it has no public
route.

After an authorized rollout, verify one Alloy Pod per schedulable node, successful
writes to Loki, and absence of platform namespace streams in Grafana.
