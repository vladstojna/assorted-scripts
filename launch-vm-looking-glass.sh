#!/usr/bin/env bash

echoerr() {
    printf "%s\n" "$*" >&2
}

print_usage() {
    echoerr "Usage: $0 <name>"
}

get_audio_backend() {
    virsh --connect "$1" dumpxml "$2" |
        xmllint --xpath 'string(/domain/devices/audio/@type)' -
    return $?
}

get_spice_port() {
    local xpath_string='string(/domain/devices/graphics[@type="spice"]/@port)'
    local port exit_code
    port="$(virsh --connect "$1" dumpxml "$2" | xmllint --xpath "$xpath_string" -)"
    if $? -ne 0; then
        return $?
    fi
    if [ "$port" -eq -1 ]; then
        port=5900
    fi
    echo "$port"
    return 0
}

if [ $# -ne 1 ]; then
    print_usage
    exit 1
fi

readonly name="$1"
readonly session_uri="qemu:///system"

if virsh --connect "$session_uri" list --name --state-running | grep "^$name$" >/dev/null; then
    echoerr "Found running VM with name '$name'"
    audio_backend="$(get_audio_backend "$session_uri" "$name")"
    jack_success=0
    exit_code=0
    if [ "$audio_backend" = "jack" ]; then
        if ! launch-vm-jack-patchbay connect "$session_uri" "$name"; then
            jack_success=$?
            echoerr "Error connecting VM jack ports"
        fi
    fi
    if ! looking-glass-client -p "$(get_spice_port "$session_uri" "$name")"; then
        echoerr "Error running looking-glass-client"
        exit_code=$?
    fi
    if [ "$audio_backend" = "jack" ] && [ $jack_success -eq 0 ]; then
        if ! launch-vm-jack-patchbay disconnect "$session_uri" "$name"; then
            echoerr "Error disconnecting VM jack ports"
        fi
    fi
    exit $exit_code
else
    echoerr "No running VM with name '$name' found"
    if ! virsh --connect "$session_uri" list --name --all | grep "^$name$" >/dev/null; then
        echoerr "No VM with name '$name' found"
    fi
    exit 1
fi
