#!/usr/bin/env bash

set -eu

print_usage() {
  cat <<EOF
  Usage:
      $0 <option>
  <option>:
      --send [window]
          Put [window] into scratchpad or focused window if [window] is not provided
      --remove <window>
          Remove <window> from scratchpad
      --list
          List windows present in scratchpad
      --help
          Print this menu and exit
EOF
}

scratchpad_name() {
  echo -en '\u2026'
}

add_scratchpad_desktop() {
  local name
  name="$(scratchpad_name)"
  if ! bspc query -D --desktop "$name" >/dev/null 2>&1; then
    bspc monitor --add-desktops "$name"
    bspc desktop "$name" --layout monocle
  fi
  echo "$name"
}

remove_scratchpad_desktop() {
  local name
  name="$(scratchpad_name)"
  if bspc query -D --desktop "$name" 2>/dev/null && ! bspc query -N -d "$name"; then
    bspc desktop "$name" --remove
  fi
  echo "$name"
}

currently_focused_window() {
  bspc query -N -n '.focused'
}

send_to_scratchpad() {
  local window
  local desktop
  window="${1:-$(currently_focused_window)}"
  desktop="$(add_scratchpad_desktop)"
  bspc node "$window" --to-desktop "$desktop"
}

remove_from_scratchpad() {
  local window="$1"
  bspc node "$window" --to-desktop focused --focus
  remove_scratchpad_desktop >/dev/null
}

list_scratchpad_windows() {
  bspc query -N -d "$(scratchpad_name)"
}

main() {
  if [ $# -lt 1 ]; then
    print_usage
    return 1
  fi

  case "$1" in
  "--send")
    send_to_scratchpad "${2:-}"
    ;;
  "--remove")
    if [ $# -lt 2 ]; then
      print_usage
      return 1
    fi
    remove_from_scratchpad "$2"
    ;;
  "--list")
    list_scratchpad_windows
    ;;
  "--help")
    print_usage
    ;;
  *)
    print_usage
    return 1
    ;;
  esac
}

main "$@"
