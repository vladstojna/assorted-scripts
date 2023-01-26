#!/usr/bin/env bash

set -e
set -u

show=(default custom clock_only max_underclock)
declare -A modes=(
    [default]="Default;0;0"
    [custom]="Custom;150;1000"
    [clock_only]="Custom Clock Only;150;0"
    [max_underclock]="Maximum Underclock;-200;-2000"
)

write_message() {
    text="<span font_size=\"medium\">$1</span>"
    echo -n "$text"
}

print_selection() {
    echo -e "$1" | $(
        read -r -d '' entry
        echo "echo $entry"
    )
}

echo -e "\0no-custom\x1ftrue"
echo -e "\0markup-rows\x1ftrue"

declare -A messages
for profile in "${show[@]}"; do
    IFS=';' read -ra values <<<"${modes[$profile]}"
    name="${values[0]}"
    clock_offset="${values[1]}"
    memory_offset="${values[2]}"
    messages[$profile]=$(write_message "$name - Clock: $clock_offset Memory: $memory_offset")
done

if [ $# -eq 1 ]; then
    selection="$1"
    for profile in "${show[@]}"; do
        if [ "$selection" = "$(print_selection "${messages[$profile]}")" ]; then
            IFS=';' read -ra values <<<"${modes[$profile]}"
            clock_offset="${values[1]}"
            memory_offset="${values[2]}"
            if ! nvidia-settings -a "GPUGraphicsClockOffset[3]=$clock_offset" >/dev/null 2>&1; then
                echo "Error setting clock offset of $clock_offset"
                exit 1
            fi
            if ! nvidia-settings -a "GPUMemoryTransferRateOffset[3]=$memory_offset" >/dev/null 2>&1; then
                echo "Error setting clock offset of $clock_offset"
                exit 1
            fi
            exit 0
        fi
    done
    echo "Invalid selection $selection" >&2
    exit 1
elif [ $# -eq 0 ]; then
    echo -e "\0prompt\x1fProfiles"
    for profile in "${show[@]}"; do
        echo "${messages[$profile]}"
    done
else
    echo "Invalid number of arguments ($# arguments passed, expected 1)" >&2
    exit 1
fi
