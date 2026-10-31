#!/bin/sh
# User-session tools only. Never changes services, installs packages or elevates.
export LC_ALL=C
audio_outputs() {
    pactl list sinks 2>/dev/null | awk '/^[[:space:]]*Name: / {name=$2} /^[[:space:]]*Description: / {sub(/^[[:space:]]*Description: /, ""); print name "\t" $0}'
}
case "${1:-read}" in
    output)
        command -v pactl >/dev/null 2>&1 || exit 1
        audio_outputs | cut -f1 | grep -Fx -- "${2:-}" >/dev/null || exit 1
        exec pactl set-default-sink "$2" ;;
    mic-mute) exec pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
    previous|play-pause|next) exec playerctl "$1" ;;
    scan) exec nmcli device wifi rescan ;;
    connect-profile)
        nmcli -g UUID connection show | grep -Fx -- "${2:-}" >/dev/null || exit 1
        exec nmcli connection up uuid "$2" ;;
    disconnect)
        nmcli -g DEVICE device status | grep -Fx -- "${2:-}" >/dev/null || exit 1
        exec nmcli device disconnect "$2" ;;
    wifi)
        # BSSID is selected from the current list; SSIDs stay one quoted argument.
        nmcli --escape no -g BSSID device wifi list | grep -Fx -- "${3:-}" >/dev/null || exit 1
        # nmcli reads a password from stdin; it is never placed in command arguments.
        exec nmcli --ask device wifi connect "${2:-}" bssid "$3" ;;
    read) ;;
    *) exit 1 ;;
esac
if command -v pactl >/dev/null 2>&1; then
    default=$(pactl get-default-sink 2>/dev/null)
    printf 'default\t%s\n' "$default"
    audio_outputs | while IFS= read -r line; do printf 'output\t%s\n' "$line"; done
    printf 'mic\t%s\n' "$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null)"
fi
if command -v playerctl >/dev/null 2>&1; then
    player=$(playerctl -l 2>/dev/null | head -1)
    if [ -n "$player" ]; then
        printf 'media\t%s\t%s\n' "$player" "$(playerctl metadata --format '{{artist}} — {{title}}' 2>/dev/null | tr '\n\t' '  ' | sed 's/ *$//')"
    fi
fi
if command -v nmcli >/dev/null 2>&1 && nmcli general status >/dev/null 2>&1; then
    printf 'nm\tavailable\n'
    nmcli -t -f NAME,UUID,TYPE,DEVICE connection show --active 2>/dev/null | while IFS= read -r line; do printf 'active\t%s\n' "$line"; done
    nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,BSSID device wifi list --rescan no 2>/dev/null | while IFS= read -r line; do printf 'wifi\t%s\n' "$line"; done
    nmcli -t -f NAME,UUID,TYPE connection show 2>/dev/null | while IFS= read -r line; do printf 'saved\t%s\n' "$line"; done
else
    printf 'nm\tunavailable\n'
fi