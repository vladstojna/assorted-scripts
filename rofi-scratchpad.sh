#!/usr/bin/env bash

set -eu

echoerr() {
  printf "%s\n" "$*" >&2
}

write_message() {
  local text="<span font_size=\"medium\">$1</span>"
  echo -n "$text"
}

declare -a hidden_windows
readonly tmp_file_prefix="/tmp/scratchpad-icon"

populate_candidates() {
  local window
  while read -r window; do
    hidden_windows+=("$window")
  done < <(bspwm-scratchpad --list)
}

get_padding() {
  local window
  local padding=0
  for window in "${hidden_windows[@]}"; do
    class="$(xdotool getwindowclassname "$window")"
    if [ -n "$class" ] && [ "${#class}" -gt "$padding" ]; then
      padding="${#class}"
    fi
  done
  echo "$padding"
}

get_entry_text() {
  local -r window="$1"
  local -r padding="$2"
  local class name
  class="$(xdotool getwindowclassname "$window")"
  name="$(xdotool getwindowname "$window")"
  if [ -n "$class" ] && [ -n "$name" ]; then
    printf "%-${padding}s - %s" "$class" "$name"
  fi
}

menu() {
  local text padding
  padding="$(get_padding)"
  local valid_idx=0
  for window in "${hidden_windows[@]}"; do
    text="$(get_entry_text "$window" "$padding")"
    if [ -n "$text" ]; then
      local icon_path="${tmp_file_prefix}${valid_idx}.png"
      extract-window-icon "$window" >"$icon_path"
      echo -en "$(write_message "$text")\0icon\x1f${icon_path}\n"
      valid_idx=$((valid_idx + 1))
    fi
  done
}

execute_selection() {
  local selection="$1"
  local window padding
  padding="$(get_padding)"
  for window in "${hidden_windows[@]}"; do
    if [ "$(write_message "$(get_entry_text "$window" "$padding")")" = "$selection" ]; then
      bspwm-scratchpad --remove "$window"
    fi
  done
}

main() {
  echo -e "\0no-custom\x1ftrue"
  echo -e "\0markup-rows\x1ftrue"
  echo -e "\0prompt\x1fScratchpad"
  populate_candidates
  if [ $# -eq 0 ]; then
    menu
  elif [ $# -eq 1 ]; then
    execute_selection "$1"
  else
    echoerr "Invalid number of arguments ($# arguments passed, expected 1)"
    exit 1
  fi
}

main "$@"
