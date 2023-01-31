#!/usr/bin/env bash

set -e
set -u

echoerr() {
    printf "%s\n" "$*" >&2
}

print_usage() {
    echoerr "Usage: $0 <step>"
}

backlight_directory() {
    local prefix="/sys/class/backlight"
    local acpi_backlight_driver
    acpi_backlight_driver="$(find "$prefix" ! -type d -printf '%f' | head -n 1)"
    if [ -z "$acpi_backlight_driver" ]; then
        echoerr "No backlight driver loaded"
        return 1
    fi
    echo "$prefix/$acpi_backlight_driver"
    return 0
}

main() {
    if [ $# -ne 1 ]; then
        print_usage
        exit 1
    fi

    local step="$1"
    local msg_tag="backlight_brightness"
    local brightness_file current_brightness new_brightness

    brightness_file="$(backlight_directory)/brightness"
    max_brightness_file="$(backlight_directory)/max_brightness"

    current_brightness="$(cat "$brightness_file")"
    max_brightness="$(cat "$max_brightness_file")"

    new_brightness=$((current_brightness + step))
    if [ "$new_brightness" -lt 0 ]; then
        new_brightness=0
    elif [ "$new_brightness" -gt "$max_brightness" ]; then
        new_brightness="$max_brightness"
    fi

    echoerr "Current brightness: $current_brightness"
    echoerr "Max brightness: $max_brightness"
    echoerr "New brightness: $new_brightness"

    echo "$new_brightness" >"$brightness_file"

    if [ "$new_brightness" -ne "$current_brightness" ]; then
        dunstify -a "changeBrightness" -u low -h "string:x-dunst-stack-tag:$msg_tag" \
            -h "int:value:$new_brightness" "Brightness: ${new_brightness}%"
    fi
}

main "$@"
