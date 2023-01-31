#!/usr/bin/env bash

set -e
set -u

echoerr() {
    printf "%s\n" "$*" >&2
}

print_usage() {
    echoerr "Usage: $0 [sink=@DEFAULT_SINK@]"
}

sanitize_step() {
    local -r step="$1"
    grep -qE \
        -e '^[+-]?[0-9]+(\.[0-9]+)?((dB)|(%))$' \
        <<<"$step"
}

main() {
    local -r sink="${1:-"@DEFAULT_SINK@"}"
    local -r msg_tag="pulseaudio_volume"

    pactl set-sink-mute "$sink" toggle
    if [ "$(pactl get-sink-mute "$sink" | awk '{ print $2 }')" = "yes" ]; then
        dunstify -a "changePulseaudioVolume" -u low \
            -i audio-volume-muted \
            -h "string:x-dunst-stack-tag:$msg_tag" \
            "Volume: muted"
    else
        local -r current_volume="$(pactl get-sink-volume "$sink" |
            head -n 1 |
            awk '{ print $5}')"
        dunstify -a "changePulseaudioVolume" -u low \
            -i audio-volume-high \
            -h "string:x-dunst-stack-tag:$msg_tag" \
            "Volume: ${current_volume}"
    fi
}

main "$@"
