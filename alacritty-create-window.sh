#!/usr/bin/env bash

alacritty_win="$(xdotool search --class Alacritty | head -n 1)"
if [ -z "$alacritty_win" ]; then
    exec alacritty
else
    win_pid="$(xdotool getwindowpid "$alacritty_win")"
    alacritty msg --socket "/run/user/$UID/Alacritty-:0-${win_pid}.sock" \
        create-window
fi
