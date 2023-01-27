#!/usr/bin/env bash

set -e
set -u

echoerr() {
    printf "%s\n" "$*" >&2
}

notify() {
    tee >&2 >(xargs -r -I{} notify-send "$1" {})
}

write_message() {
    local text="<span font_size=\"medium\">$1</span>"
    echo -n "$text"
}

readonly SYMLINK_NAME="skyrimse-executable"
declare -A candidate_files
declare -a candidate_files_ordered
previously_set_candidate=

populate_candidates() {
    local path="$1"
    local file current_file

    current_file=$(readlink "$path/$SYMLINK_NAME")
    if [ -z "$current_file" ]; then
        echoerr "populate_candidates(): symbolic link $path/$SYMLINK_NAME does not exist"
    fi
    while read -r file; do
        echoerr "populate_candidates() $file"
        if [ -n "$current_file" ] && [ "$current_file" = "$file" ]; then
            candidate_files["$file"]="$(write_message "$file")"
            previously_set_candidate="$file"
        else
            candidate_files["$file"]="$(write_message "$file")"
        fi
        candidate_files_ordered+=("$file")
    done < <(find "$path" -type f -name 'skyrimse-*' -printf '%f\n' | sort)

    # put previously selected entry at the end of the array
    local tmp=()
    for x in "${candidate_files_ordered[@]}"; do
        if [ "$previously_set_candidate" != "$x" ]; then
            tmp+=("$x")
        fi
    done
    candidate_files_ordered=("${tmp[@]}" "$previously_set_candidate")
}

menu() {
    local file
    for file in "${candidate_files_ordered[@]}"; do
        if [ "$previously_set_candidate" = "$file" ]; then
            local icon="<span color=\"white\" font_size=\"medium\">\u25b8</span>"
            echo -e "${candidate_files["$file"]}\0icon\x1f$icon"
        else
            echo "${candidate_files["$file"]}"
        fi
    done
}

execute_selection() {
    local file
    local path="$1"
    local selection="$2"
    for file in "${candidate_files_ordered[@]}"; do
        if [ "$selection" = "${candidate_files["$file"]}" ]; then
            if ! cd "$path"; then
                echo "execute_selection() cd $path -> $?" | notify "Error"
                return 1
            fi
            ln -sfnv "$file" "$SYMLINK_NAME" | notify "Launcher changed"
            return $?
        fi
    done
    echoerr "execute_selection() no match for selection '$selection'"
    return 1
}

main() {
    local launchers_prefix="${launchers_prefix:-"$HOME/scripts/steam-launch"}"
    echoerr "main(): launchers prefix is '$launchers_prefix'"
    if [ ! -d "$launchers_prefix" ]; then
        echo "main(): launchers prefix is not a directory" | notify "Error"
        exit 1
    fi
    echo -e "\0no-custom\x1ftrue"
    echo -e "\0markup-rows\x1ftrue"
    echo -e "\0prompt\x1fChoose launcher for Skyrim SE"
    populate_candidates "$launchers_prefix"
    if [ $# -eq 0 ]; then
        menu
    elif [ $# -eq 1 ]; then
        execute_selection "$launchers_prefix" "$1"
    else
        echoerr "Invalid number of arguments ($# arguments passed, expected 1)"
        exit 1
    fi
}

main "$@"
