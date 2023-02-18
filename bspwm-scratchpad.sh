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
EOF
}

currently_focused_window() {
  bspc query -N -n '.focused'
}

send_to_scratchpad() {
  local window
  window="${1:-$(currently_focused_window)}"
  bspc node "$window" --flag hidden=on --to-desktop "^1"
}

remove_from_scratchpad() {
  local window="$1"
  bspc node "$window" --flag hidden=off --to-desktop focused
  xdotool windowfocus "$window"
  bspc node "$window" --focus
}

main() {
  if [ $# -lt 1 ]; then
    print_usage
    return 1
  fi

  local -r option="$1"
  case "$option" in
  "--send")
    local -r window="${2:-}"
    send_to_scratchpad "$window"
    ;;
  "--remove")
    if [ $# -lt 2 ]; then
      print_usage
      return 1
    fi
    local -r window="$2"
    remove_from_scratchpad "$window"
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
