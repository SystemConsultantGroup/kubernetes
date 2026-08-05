if (($# != 1)); then
    echo "Usage: t secrets recipients remove <name>" >&2
    return 2
fi

name="$1"
require_file "$SECRET_STATE_FILE"
require_file "$SOPS_CONFIG_FILE"
recipient="$(NAME="$name" yq -r '.recipients[strenv(NAME)] // ""' "$SECRET_STATE_FILE")"
[[ -n "$recipient" ]] || {
    echo "Unknown recipient: $name" >&2
    return 1
}
[[ "$(yq '.recipients | length' "$SECRET_STATE_FILE")" -gt 1 ]] || {
    echo "Cannot remove the last recipient" >&2
    return 1
}

NAME="$name" rekey_secrets yq -i 'del(.recipients[strenv(NAME)])' "$SECRET_STATE_FILE"
echo "Removed recipient: $name"
