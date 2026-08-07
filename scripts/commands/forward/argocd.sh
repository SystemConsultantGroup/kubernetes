require_no_args "k forward argocd" "$@"

echo "Forwarding Argo CD at http://localhost:8080. Press Ctrl+C to stop."
kubectl port-forward service/argocd-server -n argocd 8080:443
