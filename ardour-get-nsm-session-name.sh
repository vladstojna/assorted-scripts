#!/bin/sh

journalctl --boot --user --user-unit nsmd.service --identifier=nsmd |
    grep -o 'Process Ardour.* has pid' |
    awk '{ print  $2 }'
