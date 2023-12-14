#!/bin/sh

set -eu

systemctl --user stop nsm-generic-mixer-session-save.timer
oscli send --host "$NSM_GENERIC_MIXER_HOST" \
  --port "$NSM_GENERIC_MIXER_PORT" \
  '/nsm/server/close'

