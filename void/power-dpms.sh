#!/bin/sh
# Bildschirm-Timeout (DPMS) wie Titus: Status lesen oder Sekunden setzen (0 = aus).
set -u
case "${1:-}" in
    status)
        xset q 2>/dev/null | awk '/DPMS is/ {en = ($3 == "Enabled") ? 1 : 0} /Standby:/ {t = $2} END {printf "%s %s\n", en + 0, t + 0}' ;;
    set)
        s=${2:-}
        case "$s" in ''|*[!0-9]*) exit 2 ;; esac
        if [ "$s" -gt 0 ]; then xset +dpms && xset dpms "$s" "$s" "$s"; else xset -dpms; fi ;;
    *) exit 2 ;;
esac
