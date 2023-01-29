#!/usr/bin/env bash

main() {
    if [ $# -eq 0 ]; then
        echo -e "\0no-custom\x1ftrue"
        echo -e "\0markup-rows\x1ftrue"
        echo -e "\0prompt\x1fFilter"
        local sxhkdrc="$HOME/.config/sxhkd/sxhkdrc"
        awk '/^[a-z]/ && last {print $0,"\t",last} {last=""} /^#/{last=$0}' "$sxhkdrc" |
            column -t -s $'\t'
    fi
}

main "$@"
