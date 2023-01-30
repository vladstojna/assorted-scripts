#!/bin/bash

get_game_env() {
    "$(dirname "$(readlink -e "$0")")/../env-generic-dxvk-game.sh"
}

cat <<EOF
$(get_game_env) DXVK_FRAME_RATE=60 \
$(sed -r "s/proton waitforexitandrun .*/proton waitforexitandrun/") \
$(source "$(dirname "$0")/skyrimse-executable")
EOF
