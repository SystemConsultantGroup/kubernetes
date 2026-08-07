require_optional_yes "k upgrade argocd [--yes]" "$@"

chart="$(helm list --namespace argocd --filter '^argocd$' --output json | yq -p=json -r '.[0].chart // ""')"
[[ -n "$chart" ]] || { echo "Argo CD is not installed" >&2; return 1; }
current="${chart#argo-cd-}"
if [[ "$current" == "$ARGOCD_VERSION" ]]; then
    echo "Argo CD chart already runs $current"
    return
fi

confirm_action "k upgrade argocd [--yes]" "Upgrade the Argo CD chart to $ARGOCD_VERSION?" "$@"
run install argocd
