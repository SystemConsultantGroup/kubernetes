require_no_args "t secrets recipients list" "$@"
require_file "$SECRET_STATE_FILE"

me=""
key_file="$(age_key_file)"
[[ ! -f "$key_file" ]] || me="$(age-keygen -y "$key_file")"

while IFS=$'\t' read -r name recipient; do
    marker=""
    [[ "$recipient" != "$me" ]] || marker=" (me)"
    printf '%-24s %s%s\n' "$name" "$recipient" "$marker"
done < <(yq -r '.recipients | to_entries | sort_by(.key) | .[] | [.key, .value] | @tsv' "$SECRET_STATE_FILE")
