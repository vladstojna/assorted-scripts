#!/usr/bin/env bash

active_win="$(xdotool getactivewindow)"
active_win_class=$(xprop -id "$active_win" | grep WM_CLASS)

if [[ "$active_win_class" == *"Alacritty"* ]]; then
	active_win_pid="$(xdotool getwindowpid "$active_win")"
	if [ -z "$active_win_pid" ]; then
		exec alacritty "$@"
	fi

	child_pid="$(pgrep -oP "$active_win_pid")"
	if [ -z "$child_pid" ]; then
		exec alacritty "$@"
	fi

	pushd "/proc/$child_pid/cwd" >/dev/null || exit 1
	shell_cwd="$(pwd -P)"
	popd >/dev/null || exit 1

	exec alacritty --working-directory "$shell_cwd" "$@"
else
	exec alacritty "$@"
fi
