#!/bin/sh

echoerr() {
    printf "%s\n" "$*" >&2
}

print_usage() {
    echoerr "Usage: $0 <instance> <args...>"
}

if [ $# -lt 1 ]; then
    print_usage
    exit 1
fi

instance="$1"
shift
instance_dir="$HOME/.local/share/games/mod-organizer2-$instance"

exec env \
    WINEESYNC=1 \
    WINEFSYNC=1 \
    WINEPREFIX="$HOME/.local/share/games/.sandbox/mod-organizer2" \
    wine "$instance_dir/ModOrganizer.exe" "$@"
