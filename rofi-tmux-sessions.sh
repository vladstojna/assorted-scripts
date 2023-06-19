#!/usr/bin/env bash

set -eu

echoerr() {
    printf "%s\n" "$*" >&2
}

write_message() {
    if [ -z "${FONT_DESC:-}" ]; then
        echo -n "$1"
    else
        echo -n "<span font_desc=\"$FONT_DESC\">$1</span>"
    fi
}

declare -a tmux_session_names
declare -A tmux_sessions

populate_candidates() {
    local session
    while IFS=':' read -r session_name rest; do
        tmux_session_names+=("$session_name")
        tmux_sessions["$session_name"]="$rest"
    done < <(tmux ls)
}

format_entry() {
    printf "%-16s%s\n" "$1" "$2"
}

menu() {
    local session text
    for session in "${tmux_session_names[@]}"; do
        text="$(format_entry "$session" "${tmux_sessions[$session]}")"
        echo -en "$(write_message "$text")\0info\x1f${session}\n"
    done
}

declare -r TERM_EMULATOR="${TERM_EMULATOR}"

main() {
    echo -e "\0no-custom\x1ftrue"
    echo -e "\0markup-rows\x1ftrue"
    echo -e "\0prompt\x1ftmux"
    populate_candidates
    if [ $# -eq 0 ]; then
        menu
    elif [ $# -eq 1 ]; then
        systemd-run --user "$TERM_EMULATOR" -e tmux attach -t "$ROFI_INFO"
    else
        echoerr "Invalid number of arguments ($# arguments passed, expected 1)"
        exit 1
    fi
}

main "$@"
