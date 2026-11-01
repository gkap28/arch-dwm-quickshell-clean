#!/bin/sh
# Fuellt die dwm-Leiste: Uhrzeit, WLAN und Akku. Laeuft als Hintergrundschleife.
set -u
. "$HOME/.local/share/dwm-void/clock-format.sh"
while :; do
    seconds=$(sh "$HOME/.local/share/dwm-void/center-settings.sh" read 2>/dev/null | sed -n 's/^seconds=//p')
    if [ "$seconds" = 1 ]; then set -- $(date '+%w %d %m %H.%M.%S'); else set -- $(date '+%w %d %m %H.%M'); fi
    zeit=$(clock_text "$@")
    wlan=''
    for w in /sys/class/net/*; do
        [ -d "$w/wireless" ] || continue
        if [ "$(cat "$w/operstate" 2>/dev/null)" = up ]; then
            wlan='WLAN an'
        else
            wlan='WLAN aus'
        fi
        break
    done
    bat=''
    for b in /sys/class/power_supply/BAT*; do
        [ -d "$b" ] || continue
        cap=$(cat "$b/capacity" 2>/dev/null) || continue
        st=$(cat "$b/status" 2>/dev/null)
        case "$st" in
            Charging) st='laedt' ;;
            Discharging) st='entlaedt' ;;
            Full) st='voll' ;;
        esac
        bat="Akku $cap% $st"
        break
    done
    line="$zeit"
    [ -n "$wlan" ] && line="$wlan | $line"
    [ -n "$bat" ] && line="$bat | $line"
    xsetroot -name "$line"
    sleep 1
done
