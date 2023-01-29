#!/usr/bin/env bash

echoerr() {
  printf "%s\n" "$*" >&2
}

print_usage() {
  echoerr "Usage: $0 <connect|disconnect>"
}

get_session_name() {
  "$(dirname "$(readlink -e "$0")")/ardour-nsm-session-name.sh"
}

ardour_session="${ardour_session:-$(get_session_name)}"
slave_client="${slave_client:-desktop2}"

declare -A ardour_output_buses=(
  ["game/audio_out"]="1;2"
  ["browser/audio_out"]="3;4"
  ["voip/audio_out"]="5;6"
  ["music/audio_out"]="7;8"
  ["media/audio_out"]="9;10"
  ["mic/audio_out"]="11"
)

declare -A ardour_input_buses=(
  ["game/audio_in"]="1;2"
  ["browser/audio_in"]="3;4"
  ["voip/audio_in"]="5;6"
  ["music/audio_in"]="7;8"
  ["media/audio_in"]="9;10"
)

if [ $# -ne 1 ]; then
  print_usage
  exit 1
fi
if [ "$1" != 'connect' ] && [ "$1" != 'disconnect' ]; then
  print_usage
  exit 1
fi

for outbus in "${!ardour_output_buses[@]}"; do
  IFS=';' read -ra to_slave_elems <<<"${ardour_output_buses[$outbus]}"
  for elem_idx in "${!to_slave_elems[@]}"; do
    connect_from="${ardour_session}:${outbus} $((elem_idx + 1))"
    connect_to="${slave_client}:to_slave_${to_slave_elems[$elem_idx]}"
    echo "jack_$1 \"$connect_from\" \"$connect_to\""
    "jack_$1" "$connect_from" "$connect_to"
  done
done

for inbus in "${!ardour_input_buses[@]}"; do
  IFS=';' read -ra from_slave_elems <<<"${ardour_input_buses[$inbus]}"
  for elem_idx in "${!from_slave_elems[@]}"; do
    connect_from="${slave_client}:from_slave_${from_slave_elems[$elem_idx]}"
    connect_to="${ardour_session}:${inbus} $((elem_idx + 1))"
    echo "jack_$1 \"$connect_from\" \"$connect_to\""
    "jack_$1" "$connect_from" "$connect_to"
  done
done
