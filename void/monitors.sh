#!/bin/sh
# Restore only Georg's confirmed dual-monitor setup; absent screens stay untouched.
set -eu
command -v xrandr >/dev/null 2>&1 || exit 0
outputs=$(xrandr --query) || exit 0
printf '%s\n' "$outputs" | grep -q '^HDMI-A-0 connected' || exit 0
printf '%s\n' "$outputs" | grep -q '^DisplayPort-2 connected' || exit 0
xrandr --output HDMI-A-0 --mode 2560x1080 --pos 0x0 --rotate normal \
       --output DisplayPort-2 --mode 1920x1080 --pos 2560x0 --rotate normal || {
    echo 'Monitoranordnung nicht anwendbar; Desktop startet mit aktueller Anordnung.' >&2
    exit 0
}