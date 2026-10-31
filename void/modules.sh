#!/bin/sh
# Read-only bar state; actions use only the user's existing audio/network tools.
export LC_ALL=C
case "${1:-status}" in
    up|down|mute)
        command -v pactl >/dev/null 2>&1 || exit 0
        case "$1" in
            up) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
            down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
            mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
        esac
        exit ;;
    volume)
        case "${2:-}" in ''|*[!0-9]*) exit 1 ;; esac
        [ "$2" -le 100 ] || exit 1
        command -v pactl >/dev/null 2>&1 || exit 0
        exec pactl set-sink-volume @DEFAULT_SINK@ "$2%" ;;
    audio-settings) command -v pavucontrol >/dev/null 2>&1 && exec pavucontrol; exit 0 ;;
    network-settings)
        if command -v nm-connection-editor >/dev/null 2>&1; then exec nm-connection-editor; fi
        if command -v nmtui >/dev/null 2>&1; then exec alacritty -e nmtui; fi
        exit 0 ;;
    status) ;;
    *) exit 1 ;;
esac
volume=-1
muted=0
if command -v pactl >/dev/null 2>&1; then
    value=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk 'match($0, /[0-9]+%/) { print substr($0,RSTART,RLENGTH-1); exit }')
    case "$value" in ''|*[!0-9]*) ;; *) volume=$value ;; esac
    case "$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)" in *yes*) muted=1 ;; esac
fi
network=offline
if command -v nmcli >/dev/null 2>&1; then
    network=$(nmcli -t -f TYPE,STATE device status 2>/dev/null | awk -F: '$2 == "connected" { if ($1 == "wifi") {print "wifi"; exit} if ($1 == "ethernet") wired=1 } END {if (wired) print "ethernet"}')
    case "$network" in *wifi*) network=wifi ;; *ethernet*) network=ethernet ;; *) network=offline ;; esac
else
    for interface in /sys/class/net/*; do
        [ "${interface##*/}" != lo ] || continue
        [ -r "$interface/operstate" ] || continue
        [ "$(cat "$interface/operstate")" = up ] || continue
        if [ -d "$interface/wireless" ]; then network=wifi; break; fi
        network=ethernet
    done
fi
printf '%s\t%s\t%s\n' "$volume" "$muted" "$network"
