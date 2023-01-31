#!/usr/bin/env bash

set -e
set -u

print_usage() {
    echo "Usage: $0 <target-directory>" >&2
}

if [ $# -ne 1 ]; then
    print_usage
    exit 1
fi

script_dir="$(realpath -e "$(dirname "$0")")"
target_dir="$(realpath -e "$1")"

cd "$target_dir"

declare -A existing_links
while read -r link; do
    existing_links["$link"]=""
done < <(find . -maxdepth 1 -type l -exec readlink {} \; | sort)

while read -r file; do
    if [[ -v existing_links["$file"] ]]; then
        echo "* Link to target '$file' already exists"
    else
        target="$file"
        file="$(basename "$file")"
        link_name="${file%%.*}"
        ln -sfnv "$target" "$link_name"
    fi
done < <(
    find "$(realpath -e --relative-to="$target_dir" "$script_dir")" \
        -maxdepth 1 -type f -executable |
        grep -v "$(basename "$0")" |
        sort
)
