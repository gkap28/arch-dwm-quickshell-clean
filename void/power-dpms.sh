#!/bin/sh
# Bildschirm-Timeout (DPMS) wie Titus: Status lesen oder Sekunden setzen (0 = aus).
set -u
# X has its own screen saver that blanks after 10 minutes; switch it off so only this setting decides.
apply() {
    xset s off s noblank
    if [ "$1" -gt 0 ]; then xset +dpms && xset dpms "$1" "$1" "$1"; else xset -dpms; fi
}
case "${1:-}" in
    status)
        xset q 2>/dev/null | awk '/DPMS is/ {en = ($3 == "Enabled") ? 1 : 0} /Standby:/ {t = $2} END {printf "%s %s\n", en + 0, t + 0}' ;;
    set)
        s=${2:-}
        case "$s" in ''|*[!0-9]*) exit 2 ;; esac
        apply "$s"
        # Remember the choice for the next login (user-local only).
        conf=$HOME/.local/share/dwm-void/config
        mkdir -p "$conf" && [ ! -L "$conf/screen-timeout" ] && printf '%s\n' "$s" > "$conf/screen-timeout" ;;
    restore)
        f=$HOME/.local/share/dwm-void/config/screen-timeout
        [ -f "$f" ] && [ ! -L "$f" ] || { xset s off s noblank; exit 0; }
        s=$(head -n1 "$f"); case "$s" in ''|*[!0-9]*) exit 0 ;; esac
        apply "$s" ;;
    *) exit 2 ;;
esac
