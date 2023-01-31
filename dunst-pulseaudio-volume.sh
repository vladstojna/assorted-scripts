#!/usr/bin/env bash

set -e
set -u

echoerr() {
    printf "%s\n" "$*" >&2
}

print_usage() {
    echoerr "Usage: $0 <step> [sink=@DEFAULT_SINK@]"
    echoerr "step: [+|-]N<dB|%>, where N is an integer or decimal number"
}

sanitize_step() {
    local -r step="$1"
    grep -qE \
        -e '^[+-]?[0-9]+(\.[0-9]+)?((dB)|(%))$' \
        <<<"$step"
}

main() {
    if [ $# -ne 1 ]; then
        print_usage
        exit 1
    fi

    local -r step="$1"
    local -r sink="${2:-"@DEFAULT_SINK@"}"
    local -r msg_tag="pulseaudio_volume"

    sanitize_step "$step"
    if echo "$step" | grep -qE '^.+%$'; then
        local -r column=5
        local -r unit=""
    else
        local -r column=7
        local -r unit="dB"
    fi

    local current_volume new_volume

    current_volume="$(pactl get-sink-volume "$sink" |
        head -n 1 |
        awk "{ print \$$column}")"
    echoerr "Current volume $current_volume"
    pactl set-sink-volume "$sink" "$step"
    new_volume="$(pactl get-sink-volume "$sink" |
        head -n 1 |
        awk "{ print \$$column}")"
    echoerr "New volume $new_volume"

    if [ "$new_volume" != "$current_volume" ]; then
        local icon
        if [ "$(pactl get-sink-mute "$sink" | awk '{ print $2 }')" = "yes" ]; then
            icon=audio-volume-muted
        else
            icon=audio-volume-high
        fi
        dunstify -a "changePulseaudioVolume" -u low \
            -i "$icon" \
            -h "string:x-dunst-stack-tag:$msg_tag" \
            "Volume: ${new_volume}$unit"
    fi
}

main "$@"
