#!/usr/bin/env bash

echoerr() {
    printf "%s\n" "$*" >&2
}

print_usage() {
    echoerr "Usage: $0 <name> [port=5900]"
}

get_audio_backend() {
    virsh --connect "$1" dumpxml "$2" |
        xmllint --xpath 'string(/domain/devices/audio/@type)' -
    return $?
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    print_usage
    exit 1
fi

name="$1"
port="${2:-5900}"
session_uri="qemu:///system"

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
    if ! looking-glass-client -p "$port"; then
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
