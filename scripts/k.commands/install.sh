if (($#)); then
  run_group install "$@"
  return
fi

require_bootstrap_secrets
validate_talos_inputs

run install kubernetes
run install cilium
run install argocd
