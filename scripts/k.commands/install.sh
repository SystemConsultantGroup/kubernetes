if (($#)); then
  run_group install "$@"
  return
fi

load_cluster_state
require_bootstrap_secrets
require_vault_secrets
validate_talos_inputs
require_vault_worker

run install kubernetes
run install cilium
run install argocd
run install vault
