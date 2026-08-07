require_no_args "k install argocd" "$@"
require_bootstrap_secrets
argocd_github_oauth_client_secret="$(read_bootstrap_secret ARGOCD_GITHUB_OAUTH_CLIENT_SECRET)"
cloudflare_api_token="$(read_bootstrap_secret CLOUDFLARE_API_TOKEN)"

argocd_dir="$ROOT_DIR/argocd/bootstrap"
require_file "$argocd_dir/values.yaml"
require_file "$argocd_dir/root-application.yaml"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
printf '%s' "$argocd_github_oauth_client_secret" | \
    kubectl -n argocd create secret generic argocd-github-oauth \
        --from-file=github.oauth.clientSecret=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd label secret argocd-github-oauth app.kubernetes.io/part-of=argocd --overwrite
unset argocd_github_oauth_client_secret

helm upgrade --install argocd \
    oci://ghcr.io/argoproj/argo-helm/argo-cd \
    --version "$ARGOCD_VERSION" \
    --namespace argocd \
    --values "$argocd_dir/values.yaml" \
    --wait \
    --timeout 10m

for namespace in cert-manager external-dns; do
    kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
    printf '%s' "$cloudflare_api_token" | \
        kubectl -n "$namespace" create secret generic cloudflare-api-token \
            --from-file=api-token=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
done
unset cloudflare_api_token namespace

kubectl apply -f "$argocd_dir/root-application.yaml"
kubectl -n argocd delete secret argocd-initial-admin-secret --ignore-not-found
