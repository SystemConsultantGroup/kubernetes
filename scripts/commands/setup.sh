require_no_args "t setup" "$@"
require_bootstrap_secrets
validate_talos_inputs

run generate talosconfig
run apply
run bootstrap
run wait talos
run generate kubeconfig
run install cilium
run install argocd
