require_optional_yes "t upgrade cilium [--yes]" "$@"

chart="$(helm list --namespace kube-system --filter '^cilium$' --output json | yq -p=json -r '.[0].chart // ""')"
[[ -n "$chart" ]] || { echo "Cilium is not installed" >&2; return 1; }
current="${chart#cilium-}"
if [[ "$current" == "$CILIUM_VERSION" ]]; then
    echo "Cilium already runs $current"
    return
fi

confirm_action "t upgrade cilium [--yes]" "Upgrade Cilium to $CILIUM_VERSION?" "$@"
run install gateway-api
cilium upgrade --version "$CILIUM_VERSION" --wait --wait-duration 10m
