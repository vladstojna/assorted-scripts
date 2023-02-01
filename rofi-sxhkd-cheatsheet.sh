#!/usr/bin/env bash

main() {
    if [ $# -eq 0 ]; then
        echo -e "\0no-custom\x1ftrue"
        echo -e "\0markup-rows\x1ftrue"
        echo -e "\0prompt\x1fFilter"
        local -r dir="$HOME/.config/sxhkd"
        local -r sxhkdrc="$dir/sxhkdrc"
        local -r extra_cfgs=("$dir"/sxhkdrc.*)
        cat "$sxhkdrc" "${extra_cfgs[@]}" |
            awk '/^[a-z]/ && last {print $0,"\t",last} {last=""} /^#/{last=$0}' |
            column -t -s $'\t'
    fi
}

main "$@"
