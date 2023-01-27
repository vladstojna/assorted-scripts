#!/usr/bin/env bash

set -e
set -u

echoerr() {
    printf "%s\n" "$*" >&2
}

write_message() {
    local text="<span font_size=\"medium\">$1</span>"
    echo -n "$text"
}

launch_looking_glass() {
    local unit_name="launch-vm-looking-glass@$1.service"
    if ! systemctl --user is-active --quiet "$unit_name"; then
        echo "Starting unit $unit_name"
        systemctl --user start "$unit_name"
    else
        echo "Unit $unit_name is already active"
    fi
}

format_entry() {
    local separator
    separator="$(head -c 8 </dev/zero | tr '\0' ' ')"
    printf "%s$separator" "id: $1" "name: $2" "state: $3"
}

readonly SESSION_URI='qemu:///system'
declare -rA ACTIONS=(
    [start]="Start"
    [suspend]="Suspend"
    [shutdown]="Shut down"
    [resume]="Resume"
    [looking_glass]="Launch Looking Glass"
)
readonly ACTIONS_AFTER_START=(looking_glass suspend shutdown)
readonly ACTIONS_FALLBACK=(start suspend shutdown resume looking_glass)

declare -A messages
declare -A virtual_machines

populate_entries() {
    local id name state
    while read -r id name state; do
        messages[$name]=$(write_message "$(format_entry "$id" "$name" "$state")")
        virtual_machines+=(["$name"]="$state")
    done < <(virsh --connect "$SESSION_URI" list --all | tail -n +3 | sed '/^[[:space:]]*$/d')
}

actions_from_state() {
    local state="$1"
    case "$state" in
    "running")
        echo "${ACTIONS_AFTER_START[@]}"
        ;;
    "paused")
        echo resume
        ;;
    "shut off")
        echo start
        ;;
    *)
        echo "${ACTIONS_FALLBACK[@]}"
        ;;
    esac
}

actions_from_chosen_action() {
    local action="$1"
    case "$action" in
    "suspend" | "shutdown" | "looking_glass")
        echoerr "actions_from_chosen_action() no more future actions"
        ;;
    "resume" | "start")
        echo "${ACTIONS_AFTER_START[@]}"
        ;;
    *)
        echoerr "actions_from_chosen_action() error"
        exit 1
        ;;
    esac
}

invalid_selection() {
    echoerr "Invalid selection: '$1'"
}

first_menu() {
    local name
    echo -e "\0prompt\x1fChoose virtual machine"
    for name in "${!virtual_machines[@]}"; do
        echo "${messages[$name]}"
    done
}

action_prompts() {
    local action
    local name="$1"
    shift 1
    echo -e "\0prompt\x1fChoose action for $name"
    for action in "$@"; do
        write_message "${ACTIONS[$action]}"
        # write trailing newline
        echo
    done
}

rofi_data_create_header() {
    local IFS='|'
    echo -e "\0data\x1f$*"
}

second_menu() {
    local name
    local selection="$1"
    echoerr "second_menu() Selection: $selection"
    for name in "${!virtual_machines[@]}"; do
        if [ "$selection" = "${messages[$name]}" ]; then
            local initial_actions
            initial_actions="$(actions_from_state "${virtual_machines[$name]}")"
            action_prompts "$name" $initial_actions
            echoerr "second_menu() success"
            # set name and actions as data for next execution of script
            rofi_data_create_header "$name" "$initial_actions"
            return 0
        fi
    done
    echoerr "second_menu() match failure"
    return 1
}

next_menus() {
    local selection="$1"
    local name="$2"
    local actions="$3"
    echoerr "next_menus() Selection: $selection"
    local action
    for action in $actions; do
        if [ "$selection" = "$(write_message "${ACTIONS[$action]}")" ]; then
            case "$action" in
            "start" | "suspend" | "shutdown" | "resume")
                virsh --connect "$SESSION_URI" "$action" "$name" |
                    tee >&2 >(xargs -r -I{} notify-send "Virtual Machine: $name" {})
                echo "$action"
                ;;
            "looking_glass")
                launch_looking_glass "$name" |
                    tee >&2 >(xargs -r -I{} notify-send "Virtual Machine: $name" {})
                echo "$action"
                ;;
            *)
                echoerr "next_menus() selection error"
                return 1
                ;;
            esac
            return 0
        fi
    done
    return 1
}

main() {
    echo -e "\0no-custom\x1ftrue"
    echo -e "\0markup-rows\x1ftrue"
    populate_entries
    if [ $# -eq 1 ]; then
        if ! second_menu "$1"; then
            local name actions chosen next_actions
            echoerr "main() ROFI_DATA: $ROFI_DATA"
            IFS='|' read -r name actions <<<"$ROFI_DATA"
            chosen=$(next_menus "$1" "$name" "$actions")
            if [ $? -ne 0 ]; then
                invalid_selection "$1"
                exit 1
            fi
            next_actions="$(actions_from_chosen_action "$chosen")"
            echoerr "main() chosen action: $chosen"
            echoerr "main() next actions: $next_actions"
            action_prompts "$name" $next_actions
            rofi_data_create_header "$name" "$next_actions"
        fi
    elif [ $# -eq 0 ]; then
        first_menu
    else
        echo "Invalid number of arguments ($# arguments passed, expected 1)" >&2
        exit 1
    fi
}

main "$@"
