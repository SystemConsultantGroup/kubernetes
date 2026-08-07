require_no_args "k secrets check" "$@"
require_file "$SECRET_STATE_FILE"
require_file "$SOPS_CONFIG_FILE"

key_file="$(age_key_file)"
require_file "$key_file"
recipient="$(local_age_recipient)"
if ! RECIPIENT="$recipient" yq -e '.recipients[] | select(. == strenv(RECIPIENT))' "$SECRET_STATE_FILE" >/dev/null; then
    echo "Your recipient is not configured: $recipient" >&2
    return 1
fi

expected="$(mktemp)"
trap 'rm -f "$expected"' EXIT
write_sops_config "$expected"
cmp -s "$expected" "$SOPS_CONFIG_FILE" || {
    echo ".sops.yaml is out of sync with secrets/state.yaml" >&2
    return 1
}

found=0
while IFS= read -r file; do
    found=1
    sops decrypt "$file" >/dev/null
    echo "OK: ${file#"$ROOT_DIR/"}"
done < <(secret_files)
((found)) || { echo "No encrypted secret files found" >&2; return 1; }
echo "Recipient: $recipient"
