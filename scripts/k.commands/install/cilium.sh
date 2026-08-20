require_no_args "k install cilium" "$@"

[[ ${RENDERED_MANIFESTS_CURRENT:-0} == 1 ]] || run render manifests
kubectl apply --server-side --field-manager=argocd-controller -f "$ROOT_DIR/.rendered/bootstrap/gateway-api.yaml"
kubectl apply --server-side --field-manager=argocd-controller -f "$ROOT_DIR/.rendered/bootstrap/cilium.yaml"
run wait kubernetes Cilium
