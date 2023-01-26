#!/usr/bin/env bash

echoerr() {
	printf "%s\n" "$*" >&2
}

print_usage() {
	echoerr "Usage: $0 <load|unload>"
}

if [[ $# -ne 1 ]]; then
	print_usage
	exit 1
fi
if [ "$1" != "load" ] && [ "$1" != "unload" ]; then
	print_usage
	exit 1
fi

module_source="module-jack-source"
module_sink="module-jack-sink"
channels=2
prefix=$USER

declare -A sink_names=(
	[game]="$prefix/sink/game"
	[voip]="$prefix/sink/voip"
	[browser]="$prefix/sink/browser"
	[media]="$prefix/sink/media"
	[music]="$prefix/sink/music"
)

declare -A source_names=(
	[mic_mon]="$prefix/src/mic_mon"
	[master]="$prefix/src/master"
	[mic]="$prefix/src/mic"
)

if [ "$1" = "load" ]; then
	for sink in "${!sink_names[@]}"; do
		client_name="${sink_names[$sink]}"
		if pactl list short modules | grep -qw "client_name=$client_name"; then
			echoerr "Module $module_sink $client_name already loaded"
		else
			pacmd load-module "$module_sink" channels="$channels" \
				sink_name="$sink" client_name="$client_name" \
				connect=false
		fi
	done
	pactl set-default-sink game

	for src in "${!source_names[@]}"; do
		client_name="${source_names[$src]}"
		if pactl list short modules | grep -qw "client_name=$client_name"; then
			echoerr "Module $module_source $client_name already loaded"
		else
			pacmd load-module "$module_source" channels="$channels" \
				source_name="$src" client_name="$client_name" \
				connect=false
		fi
	done
	pactl set-default-source mic
else
	while read -r module; do
		pactl unload-module "$(awk '{ print $1 }' <<<"$module")"
		echo "Unloaded module: $module"
	done < <(pactl list short modules | grep "$prefix/*")
fi
