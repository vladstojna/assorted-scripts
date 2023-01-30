#!/usr/bin/env bash

mkdir -p "$(dirname "$0")/bin" || exit 1
cd "$(dirname "$0")/bin" || exit 1

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
    find .. -maxdepth 1 -type f -executable |
        grep -v "$(basename "$0")" |
        sort
)
