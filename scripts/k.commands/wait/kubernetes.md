# kubernetes

Waits up to 10 minutes for every pod in every namespace to become Ready.

## Behavior

Runs:

```bash
kubectl wait -A --for=condition=Ready pod --all --timeout=10m
```

An optional component name changes only the progress messages; it does not
limit the check to that component.

## Usage

```bash
k wait kubernetes [component]
```

## Prerequisites

- `kubeconfig` exists and the cluster is reachable.

The default component label is `Kubernetes`.
The command fails when any pod has not reached Ready before the timeout.
