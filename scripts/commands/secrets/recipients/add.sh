if (($# != 2)); then
    echo "Usage: k secrets recipients add <name> <recipient>" >&2
    return 2
fi

name="$1"
recipient="$2"
[[ "$name" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || {
    echo "Invalid recipient name: $name" >&2
    return 2
}
if [[ "$recipient" != age1* ]] || ! age --encrypt --recipient "$recipient" </dev/null >/dev/null; then
    echo "Invalid age recipient" >&2
    return 2
fi
require_file "$SECRET_STATE_FILE"
require_file "$SOPS_CONFIG_FILE"

existing="$(NAME="$name" yq -r '.recipients[strenv(NAME)] // ""' "$SECRET_STATE_FILE")"
if [[ "$existing" == "$recipient" ]]; then
    echo "$name is already configured"
    return
elif [[ -n "$existing" ]]; then
    echo "Recipient name already exists: $name" >&2
    return 1
fi

existing="$(RECIPIENT="$recipient" yq -r '.recipients | to_entries[] | select(.value == strenv(RECIPIENT)) | .key' "$SECRET_STATE_FILE")"
[[ -z "$existing" ]] || {
    echo "Recipient is already configured as: $existing" >&2
    return 1
}

NAME="$name" RECIPIENT="$recipient" rekey_secrets \
    yq -i '.recipients[strenv(NAME)] = strenv(RECIPIENT)' "$SECRET_STATE_FILE"
echo "Added recipient: $name"
