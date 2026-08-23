[한국어](README.md) | English

# Reloader

This component restarts managed Deployments when a referenced Secret or
ConfigMap changes. It runs only for namespaces selected by the
`platform.scg.sh/application` label and uses annotation-based rollout triggers.

The application chart opts workloads into Secret reloads when managed Vault
integration is enabled. ApplicationSets configure Argo CD to ignore Reloader's
pod-template annotation so self-healing does not immediately undo the rollout.
Creation and deletion of referenced configuration also trigger reloads; Jobs and
CronJobs are ignored.

Keep the chart pin synchronized with `reloader.chart` in
[`../../../state.yaml`](../../../state.yaml). Changes to the namespace selector
or reload strategy can affect every managed application. Diagnose an unexpected
restart by checking the Deployment annotations and Reloader events before
changing application replicas or images.
