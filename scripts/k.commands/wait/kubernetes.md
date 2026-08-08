# kubernetes

Waits until all pods in every namespace are Ready.

## Description

Runs `kubectl wait -A --for=condition=Ready pod --all --timeout=10m` and
prints the component name in its status messages. The optional component
argument only changes the messages (`Waiting for <component>...` /
`<component> is ready`); the wait itself is always the same pod-wide check.

## Usage

```
k wait kubernetes [component]
```

## Prerequisites

- Cluster reachable via `kubeconfig` (generate with `k generate kubeconfig`).

## Notes

- Fails if any pod has not reached Ready within the 10 minute timeout.
- Default component name is `Kubernetes`.
