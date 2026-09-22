require_no_args "k install argocd" "$@"
require_bootstrap_secrets
argocd_github_oauth_client_secret="$(read_bootstrap_secret ARGOCD_GITHUB_OAUTH_CLIENT_SECRET)"
argocd_github_webhook_secret="$(read_bootstrap_secret ARGOCD_GITHUB_WEBHOOK_SECRET)"
vault_oidc_client_secret="$(read_bootstrap_secret VAULT_OIDC_CLIENT_SECRET)"
cloudflare_api_token="$(read_bootstrap_secret CLOUDFLARE_API_TOKEN)"
cloudflare_account_id="$(yq -er '.cloudflare."account-id"' "$STATE_FILE")"
cloudflare_kubernetes_tunnel_id="$(yq -er '.cloudflare.tunnels.kubernetes' "$STATE_FILE")"
zerossl_eab_hmac_key="$(read_bootstrap_secret ZEROSSL_EAB_HMAC_KEY)"

argocd_dir="$ROOT_DIR/argocd"
require_file "$argocd_dir/values.yaml"
require_file "$argocd_dir/root-application.yaml"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
printf '%s' "$argocd_github_oauth_client_secret" |
  kubectl -n argocd create secret generic argocd-github-oauth \
    --from-file=github.oauth.clientSecret=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd label secret argocd-github-oauth app.kubernetes.io/part-of=argocd --overwrite
unset argocd_github_oauth_client_secret
printf '%s' "$argocd_github_webhook_secret" |
  kubectl -n argocd create secret generic argocd-github-webhook \
    --from-file=webhook.github.secret=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd label secret argocd-github-webhook app.kubernetes.io/part-of=argocd --overwrite
unset argocd_github_webhook_secret
printf '%s' "$vault_oidc_client_secret" |
  kubectl -n argocd create secret generic argocd-vault-oidc \
    --from-file=oidc.clientSecret=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
kubectl -n argocd label secret argocd-vault-oidc app.kubernetes.io/part-of=argocd --overwrite
unset vault_oidc_client_secret
materialize_grafana_secrets

[[ ${RENDERED_MANIFESTS_CURRENT:-0} == 1 ]] || run render manifests
argocd_manifest="$ROOT_DIR/.rendered/bootstrap/argocd.yaml"
kubectl apply --server-side --field-manager=argocd-controller -f "$argocd_manifest"
while IFS= read -r job; do
  kubectl -n argocd wait --for=condition=complete "job/$job" --timeout 10m
done < <(yq eval-all -rN 'select(.kind == "Job") | .metadata.name' "$argocd_manifest")
while IFS= read -r deployment; do
  kubectl -n argocd rollout status "deployment/$deployment" --timeout 10m
done < <(yq eval-all -rN 'select(.kind == "Deployment") | .metadata.name' "$argocd_manifest")

kubectl -n argocd rollout restart deployment/argocd-applicationset-controller
kubectl -n argocd rollout status deployment/argocd-applicationset-controller --timeout 10m

for namespace in cert-manager external-dns; do
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
  printf '%s' "$cloudflare_api_token" |
    kubectl -n "$namespace" create secret generic cloudflare-api-token \
      --from-file=api-token=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
done

cloudflare_tunnel_response="$(curl --fail --silent --show-error \
  -H "Authorization: Bearer $cloudflare_api_token" \
  "https://api.cloudflare.com/client/v4/accounts/$cloudflare_account_id/cfd_tunnel/$cloudflare_kubernetes_tunnel_id/token")"
cloudflare_tunnel_token="$(jq -er 'select(.success == true) | .result' <<<"$cloudflare_tunnel_response")"
kubectl create namespace cloudflared --dry-run=client -o yaml | kubectl apply -f -
printf '%s' "$cloudflare_tunnel_token" |
  kubectl -n cloudflared create secret generic cloudflared-tunnel-token \
    --from-file=token=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
unset cloudflare_account_id cloudflare_api_token cloudflare_kubernetes_tunnel_id
unset cloudflare_tunnel_response cloudflare_tunnel_token namespace
printf '%s' "$zerossl_eab_hmac_key" |
  kubectl -n cert-manager create secret generic zerossl-eab \
    --from-file=hmac-key=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
unset zerossl_eab_hmac_key

kubectl apply -f "$argocd_dir/root-application.yaml"
kubectl -n argocd delete secret argocd-initial-admin-secret --ignore-not-found
