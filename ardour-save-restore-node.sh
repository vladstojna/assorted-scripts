#!/bin/sh

window_id=$(xwininfo -root -tree | grep 'generic-mixer - Ardour' | awk '{ print $1 }')
if [ -n "$window_id" ]; then
	notify-send "$(basename $0)" "Found Ardour mixer window $window_id"
	xdotool windowactivate "$window_id"
	xdotool key "ctrl+s"
	notify-send "$(basename $0)" "Saved Ardour session"
	bspc node -f last || bspc desktop -f last
	echo "$window_id"
else
	notify-send "$(basename $0)" "Ardour mixer window not found"
fi
