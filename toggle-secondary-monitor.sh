#!/usr/bin/env bash

secondary="${secondary:-DP-0}"
primary="${primary:-DP-2}"

if xrandr --listactivemonitors | grep -q "$secondary"; then
    xrandr --output "$secondary" --off
    exit $?
else
    xrandr --output "$secondary"  --above "$primary" --refresh 75 --mode 2560x1440
    exit $?
fi
