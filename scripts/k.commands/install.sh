if (($#)); then
  run_group install "$@"
  return
fi

load_cluster_state
require_bootstrap_secrets
validate_talos_inputs
run render manifests
RENDERED_MANIFESTS_CURRENT=1

run install kubernetes
run install cilium
run install argocd
