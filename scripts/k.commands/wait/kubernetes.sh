if (($# > 1)); then
  echo "Usage: k wait kubernetes [component]" >&2
  return 2
fi

component="${1:-Kubernetes}"
deadline=$((SECONDS + 600))
echo "Waiting for $component..."
while true; do
  pods="$(kubectl get pods --all-namespaces -o json)"
  failed="$(yq -r '.items[] | select(.status.phase == "Failed") | .metadata.namespace + "/" + .metadata.name' <<<"$pods")"
  if [[ -n $failed ]]; then
    echo "Failed pods:" >&2
    printf '%s\n' "$failed" >&2
    return 1
  fi
  pending="$(yq -r '.items[] | select(.status.phase != "Succeeded") | select([.status.conditions[]? | select(.type == "Ready" and .status == "True")] | length == 0) | .metadata.namespace + "/" + .metadata.name' <<<"$pods")"
  [[ -n $pending ]] || break
  if ((SECONDS >= deadline)); then
    echo "Pods not ready after 10 minutes:" >&2
    printf '%s\n' "$pending" >&2
    return 1
  fi
  sleep 5
done
echo "$component is ready"
