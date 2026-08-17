if (($# != 1)); then
  echo "Usage: k secrets recipients remove <name>" >&2
  return 2
fi

name="$1"
require_file "$RECIPIENTS_FILE"
require_file "$SOPS_CONFIG_FILE"
recipient="$(NAME="$name" yq -r '.recipients[strenv(NAME)] // ""' "$RECIPIENTS_FILE")"
[[ -n $recipient ]] || {
  echo "Unknown recipient: $name" >&2
  return 1
}
[[ "$(yq '.recipients | length' "$RECIPIENTS_FILE")" -gt 1 ]] || {
  echo "Cannot remove the last recipient" >&2
  return 1
}

NAME="$name" rekey_secrets yq -i 'del(.recipients[strenv(NAME)])' "$RECIPIENTS_FILE"
echo "Removed recipient: $name"
