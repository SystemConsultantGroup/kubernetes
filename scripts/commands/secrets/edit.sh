if (($# != 1)); then
    echo "Usage: t secrets edit <secret>" >&2
    echo "Available secrets:" >&2
    while IFS= read -r file; do
        printf '  %s\n' "$(basename "$file" .yaml)" >&2
    done < <(secret_files)
    return 2
fi

file="$(secret_file "$1")"
sync_sops_config
sops "$file"
