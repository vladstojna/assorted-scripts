#!/usr/bin/env bash

echoerr() {
  printf "%s\n" "$*" >&2
}

print_usage() {
  echoerr "Usage: $0 <connect|disconnect>"
}

if [ $# -ne 1 ] && [ "$1" != 'connect' ] && [ "$1" != 'disconnect' ]; then
  print_usage
  exit 1
fi

declare -rA obs_clients=(
  [general]="game;1;2"
  [browser]="browser;1;2"
  [voip]="voip;1;2"
  [music]="music;1;2"
  [media]="media;1;2"
  [mic]="mic;1;2"
)

readonly ardour_session="${ardour_session:-$(ardour-nsm-session-name)}"
readonly port_suffix="audio_out"
readonly obs_port_prefix="obs-"
readonly jack_cmd="jack_$1"

for client in "${!obs_clients[@]}"; do
  IFS=';' read -ra port_data <<<"${obs_clients[$client]}"
  port_ardour="${port_data[0]}"
  port_number=("${port_data[@]:1}")
  for pnum in "${port_number[@]}"; do
    connect_from="${obs_port_prefix}${client}:in_${pnum}"
    connect_to="${ardour_session}:${port_ardour}/${port_suffix} ${pnum}"
    echo "$jack_cmd \"$connect_from\" \"$connect_to\""
    "$jack_cmd" "$connect_from" "$connect_to"
  done
done
