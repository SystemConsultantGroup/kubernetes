if (($# > 1)); then
    echo "Usage: t wait kubernetes [component]" >&2
    return 2
fi

component="${1:-Kubernetes}"
echo "Waiting for $component..."
kubectl wait -A --for=condition=Ready pod --all --timeout=10m
echo "$component is ready"
