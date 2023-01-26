#!/usr/bin/env bash

echoerr() {
	printf "%s\n" "$*" >&2
}

print_usage() {
	echoerr "Usage: $0 <i2c bus> [input]"
	echoerr "Example: $0 1 HDMI-1"
	echoerr "if [input] is omitted, query available input sources"
}

main() {
	if [[ $# -lt 1 ]] || [[ $# -gt 2 ]]; then
		print_usage
		return 1
	fi

	declare -A inputs
	while read -r line; do
		if [[ "$line" == *"Feature"* ]]; then
			break
		fi
		IFS=': ' read -ra split_line <<<"$line"
		inputs+=([${split_line[1]}]="0x${split_line[0]}")
	done < <(ddcutil capabilities --bus="$1" 2>/dev/null |
		sed -n '/Feature: 60/,$p' |
		tail -n +3)

	if [[ $# -eq 1 ]]; then
		for input in "${!inputs[@]}"; do
			echo "${inputs[$input]}" "${input}"
		done
		return 0
	fi

	if [[ ${#inputs[@]} -eq 0 ]]; then
		echoerr "i2c bus $1 does not have the capability to control input source"
		return 2
	fi

	if [[ -z "${inputs[$2]}" ]]; then
		echoerr "Input '$2' does not exist for i2c bus $1"
		return 3
	fi

	ddcutil --bus="$1" setvcp 0x60 "${inputs[$2]}" >/dev/null
	return $?
}

main "$@"
