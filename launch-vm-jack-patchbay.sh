#!/usr/bin/env bash

echoerr() {
    printf "%s\n" "$*" >&2
}

print_usage() {
    echoerr "Usage: $0 <connect|disconnect> <session URI> <domain>"
}

get_session_name() {
    "$(dirname "$(readlink -e "$0")")/ardour-nsm-session-name.sh"
}

if [ $# -ne 3 ]; then
    print_usage
    exit 1
fi
if [ "$1" != 'connect' ] && [ "$1" != 'disconnect' ]; then
    print_usage
    exit 1
fi

jack_cmd="jack_$1"
session_uri="$2"
domain="$3"

ardour_session="${ardour_session:-$(get_session_name)}"

output_client="out-$(virsh --connect "$session_uri" dumpxml "$domain" |
    xmllint --xpath 'string(/domain/devices/audio[@type="jack"]/output/@clientName)' -)"

input_client="in-$(virsh --connect "$session_uri" dumpxml "$domain" |
    xmllint --xpath 'string(/domain/devices/audio[@type="jack"]/input/@clientName)' -)"

echo "$jack_cmd \"$output_client:output 0\" \"$ardour_session:game/audio_in 1\""
"$jack_cmd" "$output_client:output 0" "$ardour_session:game/audio_in 1"
echo "$jack_cmd \"$output_client:output 1\" \"$ardour_session:game/audio_in 2\""
"$jack_cmd" "$output_client:output 1" "$ardour_session:game/audio_in 2"
echo "$jack_cmd \"$input_client:input 0\" \"$ardour_session:mic/audio_out 1\""
"$jack_cmd" "$input_client:input 0" "$ardour_session:mic/audio_out 1"
echo "$jack_cmd \"$input_client:input 1\" \"$ardour_session:mic/audio_out 2\""
"$jack_cmd" "$input_client:input 1" "$ardour_session:mic/audio_out 2"
