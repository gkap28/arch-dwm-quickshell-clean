#!/bin/sh
# Only explicit menu actions; never elevate a user-writable helper.
set -u
fail() {
    if command -v xmessage >/dev/null 2>&1; then xmessage -center "$1"; else echo "$1" >&2; fi
    exit 1
}
case "${1:-}" in
    lock)
        if command -v slock >/dev/null 2>&1; then exec slock; fi
        if command -v i3lock >/dev/null 2>&1; then exec i3lock; fi
        fail 'Sperren: bitte zuerst slock oder i3lock installieren.' ;;
    logout) exec pkill -TERM -u "$(id -u)" -x dwm ;;
    suspend)
        command -v loginctl >/dev/null 2>&1 || fail 'Ruhezustand: elogind/loginctl fehlt.'
        loginctl suspend || fail 'Ruhezustand wurde nicht erlaubt oder wird nicht unterstuetzt.' ;;
    reboot|shutdown)
        action=$1
        if command -v loginctl >/dev/null 2>&1; then
            if [ "$action" = reboot ]; then loginctl reboot && exit 0; else loginctl poweroff && exit 0; fi
        fi
        # Run only the system's shutdown binary with sudo in a real terminal.
        binary=''
        for candidate in /usr/bin/shutdown /usr/sbin/shutdown /sbin/shutdown; do
            if [ -x "$candidate" ]; then binary=$candidate; break; fi
        done
        [ -n "$binary" ] || fail 'Der Systembefehl shutdown fehlt.'
        command -v alacritty >/dev/null 2>&1 || fail 'Alacritty fehlt fuer die Passwortabfrage.'
        if [ "$action" = reboot ]; then exec alacritty -e sudo "$binary" -r now; fi
        exec alacritty -e sudo "$binary" -h now ;;
    *) fail 'Unbekannte Aktion; nichts ausgefuehrt.' ;;
esac