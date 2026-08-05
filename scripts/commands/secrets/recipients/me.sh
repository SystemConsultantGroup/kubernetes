require_no_args "t secrets recipients me" "$@"

key_file="$(age_key_file)"
key_dir="$(dirname "$key_file")"
if [[ -e "$key_file" && ! -f "$key_file" ]]; then
    echo "Age key path is not a file: $key_file" >&2
    return 1
fi

if [[ ! -f "$key_file" ]]; then
    mkdir -p "$key_dir"
    umask 077
    age-keygen -o "$key_file"
    echo "Created age key: $key_file"
else
    echo "Using age key: $key_file"
fi
chmod 700 "$key_dir"
chmod 600 "$key_file"

recipient="$(age-keygen -y "$key_file")"
echo "Recipient: $recipient"
if [[ -f "$SECRET_STATE_FILE" ]]; then
    aliases="$(RECIPIENT="$recipient" yq -r '.recipients | to_entries[] | select(.value == strenv(RECIPIENT)) | .key' "$SECRET_STATE_FILE")"
fi
if [[ -n "${aliases:-}" ]]; then
    echo "Aliases: ${aliases//$'\n'/, }"
else
    echo "This recipient is not configured."
fi
