#!/usr/bin/env bash

set -e
set -u

print_usage() {
    echo "Generates symlinks in <target-directory> to executables in this directory (except $0)"
    echo "Provide optional [files...] arguments to generate symlinks only to those executables"
    echo "Usage: $0 <target-directory> [files...]" >&2
}

if [ $# -lt 1 ]; then
    print_usage
    exit 1
fi

script_dir="$(realpath -e "$(dirname "$0")")"
target_dir="$(realpath -e "$1")"
shift 1

cd "$target_dir"

declare -A existing_links
while read -r link; do
    existing_links["$link"]=""
done < <(find . -maxdepth 1 -type l -exec readlink {} \; | sort)

if [ $# -gt 0 ]; then
    files2link=$(
        prefix="$(realpath -e --relative-to="$target_dir" "$script_dir")"
        for file in "$@"; do
            echo "$prefix/$(basename "$file")"
        done
    )
else
    files2link=$(
        find "$(realpath -e --relative-to="$target_dir" "$script_dir")" \
            -maxdepth 1 -type f -executable |
            grep -v "$(basename "$0")" |
            sort
    )
fi

while read -r file; do
    if [[ -v existing_links["$file"] ]]; then
        echo "* Link to target '$file' already exists"
    else
        target="$file"
        file="$(basename "$file")"
        link_name="${file%%.*}"
        ln -sfnv "$target" "$link_name"
    fi
done < <(echo "$files2link")
