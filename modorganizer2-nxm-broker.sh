#!/usr/bin/env bash

echoerr() {
	printf "%s\n" "$*" >&2
}

print_usage() {
	echoerr "Usage: $0 <nxm-link>"
}

nxm_link=$1
shift

if [ -z "$nxm_link" ]; then
	print_usage
	exit 1
fi

nexus_game_id=${nxm_link#nxm://}
nexus_game_id=${nexus_game_id%%/*}

instance_dir="$HOME/.local/share/games/mod-organizer2-$nexus_game_id"
echo "Instance directory: $instance_dir"

if [ ! -d "$instance_dir" ]; then
	echoerr "Instance at $instance_dir not found"
	zenity --ok-label=Exit --ellipsize --error --text \
		"Could not download file because there is no Mod Organizer 2 instance for '$nexus_game_id'"
	exit 1
fi

instance_windir="$(sed 's/\//\\\\/g' <<<"Z:$instance_dir/ModOrganizer.exe")"
echo "Executable Windows path: $instance_windir"

if pgrep -f "$instance_windir" >/dev/null; then
	echo "Sending download '$nxm_link' to running Mod Organizer 2 instance"
	exec env \
		WINEESYNC=1 \
		WINEFSYNC=1 \
		WINEPREFIX="$HOME/.local/share/games/.sandbox/mod-organizer2" \
		wine "$instance_dir/nxmhandler.exe" "$nxm_link"
else
	echo "Starting Mod Organizer 2 to download '$nxm_link'"
	exec modorganizer2-standalone "$nexus_game_id" "$nxm_link"
fi
