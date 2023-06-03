#!/usr/bin/env bash

set -eu

echoerr() {
    printf "%s\n" "$*" >&2
}

write_message() {
    local text="<span font_size=\"medium\">$1</span>"
    echo -n "$text"
}

notify() {
    tee >&2 >(xargs -r -I{} notify-send "$1" {})
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
    printf "%s$separator" "context: $1" "id: $2" "name: $3" "state: $4"
}

readonly ROFI_DATA_SEPARATOR="|"
readonly KEY_SEPARATOR="|"
readonly SESSION_URIS=(
    'qemu:///system'
    'qemu:///session'
)
declare -rA ACTIONS=(
    [start]="Start"
    [suspend]="Suspend"
    [shutdown]="Shut down"
    [resume]="Resume"
    [looking_glass]="Launch Looking Glass"
)
readonly ACTIONS_AFTER_START=(suspend shutdown)
readonly ACTIONS_FALLBACK=(start suspend shutdown resume)

declare -A messages
declare -A virtual_machines

populate_entries() {
    local id name state
    while read -r context id name state; do
        local key="${context}${KEY_SEPARATOR}${name}"
        messages[$key]=$(write_message "$(format_entry "$context" "$id" "$name" "$state")")
        virtual_machines+=([$key]="$state")
    done < <(
        for uri in "${SESSION_URIS[@]}"; do
            echo -n "${uri##*/}"
            virsh --connect "$uri" list --all | tail -n +3 | sed '/^[[:space:]]*$/d'
        done
    )
}

is_using_looking_glass() {
    local context="$1"
    local name="$2"
    local looking_glass="looking-glass"
    local shmem
    shmem=$(virsh --connect "qemu:///$context" dumpxml "$name" |
        xmllint --xpath \
            "string(/domain/devices/shmem[starts-with(@name,\"$looking_glass\")]/@name)" -)
    [ "$shmem" = "$looking_glass" ]
}

actions_after_start() {
    local context="$1"
    local name="$2"
    local initial_state="$3"
    if is_using_looking_glass "$context" "$name"; then
        echo "looking_glass" "${ACTIONS_AFTER_START[@]}"
    elif [ "$initial_state" = "running" ]; then
        echo "${ACTIONS_AFTER_START[@]}"
    fi
}

actions_fallback() {
    local context="$1"
    local name="$2"
    if is_using_looking_glass "$context" "$name"; then
        echo "${ACTIONS_FALLBACK[@]}" "looking_glass"
    else
        echo "${ACTIONS_FALLBACK[@]}"
    fi
}

contextual_actions() {
    local context="$1"
    local name="$2"
    local initial_state="$3"
    case "$initial_state" in
    "running")
        actions_after_start "$context" "$name" "$initial_state"
        ;;
    "paused")
        echo resume
        ;;
    "shut off")
        echo start
        ;;
    *)
        actions_fallback "$context" "$name"
        ;;
    esac
}

actions_from_chosen_action() {
    local context="$1"
    local name="$2"
    local action="$3"
    local initial_state="$4"
    case "$action" in
    "suspend" | "shutdown" | "looking_glass")
        echoerr "actions_from_chosen_action() no more future actions"
        ;;
    "resume" | "start")
        actions_after_start "$context" "$name" "$initial_state"
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
    local key
    echo -e "\0prompt\x1fChoose virtual machine"
    for key in "${!virtual_machines[@]}"; do
        echo "${messages[$key]}"
    done
}

action_prompts() {
    local action
    local context="$1"
    local name="$2"
    shift 2
    echo -e "\0prompt\x1fChoose action for $name from context $context"
    for action in "$@"; do
        echoerr "$action"
        write_message "${ACTIONS[$action]}"
        # write trailing newline
        echo
    done
}

rofi_data_create_header() {
    local IFS="$ROFI_DATA_SEPARATOR"
    echo -e "\0data\x1f$*"
}

second_menu() {
    local key
    local selection="$1"
    echoerr "second_menu() Selection: $selection"
    for key in "${!virtual_machines[@]}"; do
        if [ "$selection" = "${messages[$key]}" ]; then
            local initial_actions context name state
            IFS="$KEY_SEPARATOR" read -r context name <<<"$key"
            state="${virtual_machines[$key]}"
            read -ra initial_actions < <(
                contextual_actions "$context" "$name" "$state"
            )
            action_prompts "$context" "$name" "${initial_actions[@]}"
            echoerr "second_menu() initial state: $state"
            echoerr "second_menu() success"
            # set name and actions as data for next execution of script
            rofi_data_create_header "$state" "$context" "$name" \
                "${initial_actions[*]}"
            return 0
        fi
    done
    echoerr "second_menu() match failure"
    return 1
}

next_menus() {
    local selection="$1"
    local context="$2"
    local name="$3"
    local actions="$4"
    local action
    echoerr "next_menus() Selection: $selection"
    for action in $actions; do
        if [ "$selection" = "$(write_message "${ACTIONS[$action]}")" ]; then
            case "$action" in
            "start" | "suspend" | "shutdown" | "resume")
                virsh --connect "qemu:///$context" "$action" "$name" |
                    notify "Virtual Machine: $name"
                echo "$action"
                ;;
            "looking_glass")
                launch_looking_glass "$name" | notify "Virtual Machine: $name"
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
            local context name actions chosen next_actions
            echoerr "main() ROFI_DATA: $ROFI_DATA"
            IFS="$ROFI_DATA_SEPARATOR" read -r initial_state context name actions \
                <<<"$ROFI_DATA"
            chosen=$(next_menus "$1" "$context" "$name" "$actions")
            if [ $? -ne 0 ]; then
                invalid_selection "$1"
                exit 1
            fi
            read -ra next_actions < <(
                actions_from_chosen_action "$context" "$name" "$chosen" \
                    "$initial_state"
            )
            echoerr "main() chosen action: $chosen"
            echoerr "main() next actions: ${next_actions[*]}"
            action_prompts "$context" "$name" "${next_actions[@]}"
            rofi_data_create_header "$initial_state" "$context" "$name" \
                "${next_actions[*]}"
        fi
    elif [ $# -eq 0 ]; then
        first_menu
    else
        echoerr "Invalid number of arguments ($# arguments passed, expected 1)"
        exit 1
    fi
}

main "$@"
