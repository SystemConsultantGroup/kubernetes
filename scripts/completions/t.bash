# Bash completion for t.

_T_ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
_T_COMMAND_DIR="$_T_ROOT_DIR/scripts/commands"

_t_command_names() {
    local directory="$1" file
    for file in "$directory"/*.sh; do
        [[ -f "$file" ]] && basename "$file" .sh
    done
}

_t_secret_names() {
    local file
    for file in "$_T_ROOT_DIR/secrets"/*.yaml; do
        [[ -f "$file" && "$(basename "$file")" != state.yaml ]] && basename "$file" .yaml
    done
}

_t_recipient_names() {
    yq -r '.recipients | keys | .[]' "$_T_ROOT_DIR/secrets/state.yaml" 2>/dev/null
}

_t_node_names() {
    yq -r '.nodes | keys | .[]' "$_T_ROOT_DIR/state.yaml" 2>/dev/null
}

_t_complete() {
    local current="${COMP_WORDS[COMP_CWORD]}" directory="$_T_COMMAND_DIR" choices="" part index

    for ((index = 1; index < COMP_CWORD; index++)); do
        part="${COMP_WORDS[index]}"
        if [[ -d "$directory/$part" ]]; then
            directory="$directory/$part"
        else
            directory=""
            break
        fi
    done
    [[ -z "$directory" ]] || choices="$(_t_command_names "$directory")"

    case "${COMP_WORDS[*]:1:COMP_CWORD-1}" in
        edit) choices="$(_t_secret_names)" ;;
        reset) choices="--yes $(_t_node_names)" ;;
        "reset --yes") choices="$(_t_node_names)" ;;
        reset\ *) choices="--yes" ;;
        "secrets recipient remove") choices="$(_t_recipient_names)" ;;
        "upgrade argocd"|"upgrade cilium"|"upgrade kubernetes"|"upgrade talos") choices="--yes" ;;
    esac

    mapfile -t COMPREPLY < <(compgen -W "$choices" -- "$current")
}

complete -F _t_complete t
