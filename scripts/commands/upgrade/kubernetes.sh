require_optional_yes "t upgrade kubernetes [--yes]" "$@"

current="$(kubectl version -o json | yq -p=json -r '.serverVersion.gitVersion')"
if [[ "${current#v}" == "$KUBERNETES_VERSION" ]]; then
    echo "Kubernetes already runs $current"
    return
fi

talosctl upgrade-k8s --nodes "$MAIN_IP" --to "$KUBERNETES_VERSION" --dry-run
confirm_action "t upgrade kubernetes [--yes]" "Apply this Kubernetes upgrade?" "$@"
talosctl upgrade-k8s --nodes "$MAIN_IP" --to "$KUBERNETES_VERSION"
run wait talos
