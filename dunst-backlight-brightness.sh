#!/usr/bin/env bash

set -eu

echoerr() {
    printf "%s\n" "$*" >&2
}

print_usage() {
    echoerr "Usage: $0 <step> [driver]"
    echoerr "default [driver] is the first one listed in alphabetical order"
    echoerr "<step> must be an integer preceeded optionally by + or - and followed optionally by %"
}

sanitize_step() {
    local -r step="$1"
    grep -qE \
        -e '^[+-]?[0-9]+%?$' \
        <<<"$step"
}

backlight_directory() {
    local prefix="/sys/class/backlight"
    local acpi_backlight_driver
    acpi_backlight_driver="${1:-$(
        find "$prefix" ! -type d -printf '%f\n' | sort | head -n 1
    )}"
    if [ -z "$acpi_backlight_driver" ]; then
        echoerr "No backlight driver loaded"
        return 1
    fi
    echo "$prefix/$acpi_backlight_driver"
    return 0
}

get_step_value() {
    local -r step="$1"
    echo -n "$(grep -oE '[-+]?[0-9]+' <<<"$step")"
}

normalize_step() {
    local -r step="$1"
    local -r max_br="$2"
    echo -n "$(calc "trunc($step / 100 * $max_br)" | awk '{$1=$1};1')"
}

normalize_brightness() {
    local -r current="$1"
    local -r max_br="$2"
    echo -n "$(calc "trunc($current / $max_br * 100)" | awk '{$1=$1};1')"
}

main() {
    if [ $# -lt 1 ]; then
        print_usage
        exit 1
    fi
    local -r step="$1"
    if ! sanitize_step "$step"; then
        print_usage
        exit 1
    fi

    local bl_dir brightness_file current_brightness max_brightness
    bl_dir="$(backlight_directory "${2:-}")"
    brightness_file="$bl_dir/brightness"
    current_brightness="$(cat "$brightness_file")"
    max_brightness="$(cat "$bl_dir/max_brightness")"

    local step_value
    # if step is provided as a percentage value, then normalize it relative to
    # the maximum brightness value
    if echo "$step" | grep -qE '^.+%$'; then
        step_value="$(normalize_step "$(get_step_value "$step")" "$max_brightness")"
    else
        step_value="$(get_step_value "$step")"
    fi

    # if step is provided without a + or - sign, then set the value of step as the brightness
    local new_brightness
    if echo "$step" | grep -qE '^[+-]'; then
        new_brightness=$((current_brightness + step_value))
    else
        new_brightness="$step_value"
    fi
    if [ "$new_brightness" -lt 0 ]; then
        new_brightness=0
    elif [ "$new_brightness" -gt "$max_brightness" ]; then
        new_brightness="$max_brightness"
    fi

    echoerr "Step: $step, Value: $step_value"
    echoerr "Current brightness: $current_brightness"
    echoerr "Max brightness: $max_brightness"
    echoerr "New brightness: $new_brightness"

    echo "$new_brightness" >"$brightness_file"

    if [ "$new_brightness" -ne "$current_brightness" ]; then
        local -r msg_tag="backlight_brightness"
        dunstify -a "changeBrightness" -u low -h "string:x-dunst-stack-tag:$msg_tag" \
            -h "int:value:$(normalize_brightness "$new_brightness" "$max_brightness")" \
            "Brightness: $(normalize_brightness "$new_brightness" "$max_brightness")%"
    fi
}

main "$@"
