#!/bin/sh

pacmd unload-module module-jack-sink
pacmd unload-module module-jack-source

pulse-jack-modules load
oscli send --host "$NSM_GENERIC_MIXER_HOST" \
  --port "$NSM_GENERIC_MIXER_PORT" \
  '/nsm/server/open' \
  "$NSM_GENERIC_MIXER_SESSION"
systemctl --user start nsm-generic-mixer-session-save.timer
