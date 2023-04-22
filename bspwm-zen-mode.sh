#!/usr/bin/env bash

readonly new_window_gap="${1:-2}"
readonly orig_file="/tmp/bspwm-zen-mode.orig"
readonly properties=(
	window_gap
	top_padding
	right_padding
	bottom_padding
	left_padding
	top_monocle_padding
	right_monocle_padding
	bottom_monocle_padding
	left_monocle_padding
)

zenmode_enabled() {
	[ -f "$orig_file" ]
}

zenmode_save_original_values() {
	local prop
	for prop in "${properties[@]}"; do
		echo -n "${prop},"
		bspc config "$prop"
	done
}

zenmode_restore_original_values() {
	local prop_line
	while read -r prop_line; do
		IFS=',' read -r prop prop_value <<<"$prop_line"
		bspc config "$prop" "$prop_value"
	done
}

zenmode_set_properties() {
	local -r window_gap="$1"
	local prop
	bspc config window_gap "$window_gap"
	for prop in "${properties[@]:1}"; do
		bspc config "$prop" 1
	done
}

zenmode_enable() {
	polybar-msg cmd hide
	dunstctl set-paused true
	zenmode_save_original_values >"$orig_file"
	zenmode_set_properties "$new_window_gap"
}

zenmode_disable() {
	polybar-msg cmd show
	dunstctl set-paused false
	zenmode_restore_original_values <"$orig_file"
	rm -f "$orig_file"
}

zenmode_toggle() {
	if zenmode_enabled; then
		echo "debug: zen mode is enabled, disabling" >&2
		zenmode_disable
	else
		echo "debug: zen mode is disabled, enabling" >&2
		zenmode_enable
	fi
}

main() {
	zenmode_toggle
}

main "$@"
