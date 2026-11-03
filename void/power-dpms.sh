#!/bin/sh
# Bildschirm-Timeout (DPMS) wie Titus: Status lesen oder Sekunden setzen (0 = aus).
set -u
case "${1:-}" in
    status)
        xset q 2>/dev/null | awk '/DPMS is/ {en = ($3 == "Enabled") ? 1 : 0} /Standby:/ {t = $2} END {printf "%s %s\n", en + 0, t + 0}' ;;
    set)
        s=${2:-}
        case "$s" in ''|*[!0-9]*) exit 2 ;; esac
        if [ "$s" -gt 0 ]; then xset +dpms && xset dpms "$s" "$s" "$s"; else xset -dpms; fi
        # Remember the choice for the next login (user-local only).
        conf=$HOME/.local/share/dwm-void/config
        mkdir -p "$conf" && [ ! -L "$conf/screen-timeout" ] && printf '%s\n' "$s" > "$conf/screen-timeout" ;;
    restore)
        f=$HOME/.local/share/dwm-void/config/screen-timeout
        [ -f "$f" ] && [ ! -L "$f" ] || exit 0
        s=$(head -n1 "$f"); case "$s" in ''|*[!0-9]*) exit 0 ;; esac
        if [ "$s" -gt 0 ]; then xset +dpms && xset dpms "$s" "$s" "$s"; else xset -dpms; fi ;;
    *) exit 2 ;;
esac
