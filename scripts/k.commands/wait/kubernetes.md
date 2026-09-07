# kubernetes

Waits up to 10 minutes for every active pod in every namespace to become Ready.

## Behavior

The command polls all pods. Succeeded pods are complete and do not need a Ready
condition. A failed pod stops the command immediately; every other pod must
report Ready before the deadline.

An optional component name changes only the progress messages; it does not
limit the check to that component.

## Usage

```bash
k wait kubernetes [component]
```

## Prerequisites

- `kubeconfig` exists and the cluster is reachable.

The default component label is `Kubernetes`.
The command fails when a pod fails or an active pod has not reached Ready before
the timeout.
