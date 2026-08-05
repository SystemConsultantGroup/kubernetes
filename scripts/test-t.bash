#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/completions/t.bash"

assert_completion() {
    local expected="$1" actual
    shift
    COMP_WORDS=("$@")
    COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
    _t_complete
    actual=" ${COMPREPLY[*]} "
    [[ "$actual" == *" $expected "* ]] || {
        echo "Missing completion '$expected' for: $*" >&2
        return 1
    }
}

assert_completion recipients t secrets ""
assert_completion remove t secrets recipients ""
assert_completion remove t secrets recipient ""
recipient_name="$(_t_recipient_names | head -1)"
[[ -n "$recipient_name" ]]
assert_completion "$recipient_name" t secrets recipients remove ""
assert_completion --help t --

if output="$("$ROOT_DIR/scripts/t" reset --yes not-a-node 2>&1)"; then
    echo "Unknown reset node was accepted" >&2
    exit 1
fi
[[ "$output" == "Unknown node: not-a-node" ]]

echo "t checks passed"
