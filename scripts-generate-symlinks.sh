#!/usr/bin/env bash

set -eu

print_usage() {
    echo "Generates symlinks in <target-directory> to executables in this directory (except $0)"
    echo "Provide optional [files...] arguments to generate symlinks only to those executables"
    echo "Usage: $0 <target-directory> [files...]" >&2
}

if [ $# -lt 1 ]; then
    print_usage
    exit 1
fi

script_dir="$(dirname "$0")"
target_dir="$1"
shift 1

declare -A existing_links
while read -r link; do
    existing_links["$link"]=""
done < <(find "$target_dir" -maxdepth 1 -type l -exec readlink {} \; | sort)

if [ $# -gt 0 ]; then
    files2link=$(
        for file in "$@"; do
            realpath -e --relative-to="$target_dir" "$file"
        done
    )
else
    files2link=$(
        find "$script_dir" -maxdepth 1 -type f -executable \
            -exec realpath -e --relative-to="$target_dir" {} \; |
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
        ln -sfnv "$target" "$target_dir/${file%%.*}"
    fi
done <<<"$files2link"
