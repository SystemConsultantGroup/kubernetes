require_no_args "k render manifests" "$@"

rendered_directory="$ROOT_DIR/.rendered"
temporary_directory="$(mktemp -d)"
cleanup_rendered_manifests() {
  rm -rf "$temporary_directory"
}
trap cleanup_rendered_manifests EXIT
mkdir -p "$temporary_directory/bootstrap" "$temporary_directory/gitops/platform" "$temporary_directory/applications"

curl -fsSL \
  "https://github.com/kubernetes-sigs/gateway-api/releases/download/v$GATEWAY_API_VERSION/standard-install.yaml" \
  -o "$temporary_directory/bootstrap/gateway-api.yaml"

helm template cilium cilium \
  --repo https://helm.cilium.io/ \
  --version "$CILIUM_VERSION" \
  --namespace kube-system \
  --include-crds \
  --values "$ROOT_DIR/argocd/platform/cilium/values.yaml" \
  >"$temporary_directory/bootstrap/cilium.yaml"

helm template argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm \
  --version "$ARGOCD_VERSION" \
  --namespace argocd \
  --include-crds \
  --values "$ROOT_DIR/argocd/values.yaml" \
  >"$temporary_directory/bootstrap/argocd.yaml"

kubectl kustomize "$ROOT_DIR/argocd" >"$temporary_directory/gitops/root.yaml"
while IFS= read -r customization; do
  platform_directory="$(dirname "$customization")"
  relative_directory="${platform_directory#"$ROOT_DIR/argocd/platform/"}"
  output_name="${relative_directory//\//-}"
  kubectl kustomize "$platform_directory" >"$temporary_directory/gitops/platform/$output_name.yaml"
done < <(find "$ROOT_DIR/argocd/platform" -name kustomization.yaml -type f | sort)

for application_directory in "$ROOT_DIR"/applications/*; do
  [[ -d $application_directory ]] || continue
  application="${application_directory##*/}"
  if [[ -f $application_directory/kustomization.yaml ]]; then
    kubectl kustomize "$application_directory" >"$temporary_directory/applications/$application-custom.yaml"
    continue
  fi
  metadata="$application_directory/meta.yaml"
  [[ -f $metadata ]] || continue
  for instance in production testing; do
    lock="$application_directory/instances/$instance.yaml"
    [[ -f $lock ]] || continue
    identity="$application-$instance"
    helm template "$identity" "$ROOT_DIR/argocd/charts/application" \
      --values "$metadata" \
      --values "$lock" \
      --set "_context.application=$application" \
      --set "_context.instance.type=$instance" \
      >"$temporary_directory/applications/$identity.yaml"
  done
  while IFS= read -r lock; do
    workload="$(basename "$(dirname "$lock")")"
    pull_request="$(basename "$lock" .yaml)"
    identity="$application-preview-$workload-$pull_request"
    preview_values="$temporary_directory/$identity-values.yaml"
    yq -n ".\"$workload\" = load(\"$lock\") | ._context.application = \"$application\" | ._context.instance.type = \"preview\" | ._context.instance.workload = \"$workload\" | ._context.instance.pullRequest = $pull_request" >"$preview_values"
    helm template "$identity" "$ROOT_DIR/argocd/charts/application" \
      --values "$metadata" \
      --values "$preview_values" \
      >"$temporary_directory/applications/$identity.yaml"
    rm -f "$preview_values"
  done < <(find "$application_directory/instances/preview" -mindepth 2 -maxdepth 2 -name '*.yaml' -type f 2>/dev/null | sort)
done

rm -rf "$rendered_directory"
mv "$temporary_directory" "$rendered_directory"
echo "Rendered manifests to .rendered/"
