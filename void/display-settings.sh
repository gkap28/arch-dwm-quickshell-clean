#!/bin/sh
# Titus-style Displays backend for Void: read xrandr, apply validated layouts, save for next login.
# Only the user's own X display and ~/.local/share/dwm-void/config are touched.
set -u
conf=$HOME/.local/share/dwm-void/config/monitors.conf
command -v xrandr >/dev/null 2>&1 || { echo 'Displays: xrandr fehlt (sudo xbps-install -S xrandr).' >&2; exit 1; }

list() {
    # name<TAB>enabled<TAB>primary<TAB>x<TAB>y<TAB>mode<TAB>rate<TAB>rotation<TAB>modes(WxH@rate,...)
    LC_ALL=C xrandr --query | awk '
        function flush() { if (name != "") printf "%s\t%d\t%d\t%d\t%d\t%s\t%s\t%s\t%s\n", name, en, pri, x, y, mode, rate, rot, modes }
        /^[^ ]+ connected/ {
            flush(); name = $1; en = 0; pri = 0; x = 0; y = 0; mode = ""; rate = ""; rot = "normal"; modes = ""
            for (i = 3; i <= NF; i++) {
                if ($i == "primary") pri = 1
                else if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) { en = 1; split($i, g, /[x+]/); x = g[3]; y = g[4]
                    if ($(i+1) ~ /^(left|right|inverted)$/) rot = $(i+1) }
                else if ($i ~ /^\(/) break
            }
            next
        }
        /^[^ ]/ { flush(); name = ""; next }
        name != "" && /^   [0-9]+x[0-9]+/ {
            for (i = 2; i <= NF; i++) {
                r = $i; cur = (r ~ /\*/); gsub(/[*+]/, "", r); if (r == "") continue
                modes = modes (modes == "" ? "" : ",") $1 "@" r
                if (cur) { mode = $1; rate = r }
            }
        }
        END { flush() }'
}

valid() {
    printf '%s\n' "$1" | grep -Eq '^[A-Za-z0-9_.-]+:(off|on:[01]:[0-9]{3,5}x[0-9]{3,5}:[0-9]{1,3}(\.[0-9]{1,3})?:(normal|left|right|inverted):[0-9]{1,5}:[0-9]{1,5})$'
}

apply() {
    set -- "$@"; args=''
    for spec in "$@"; do
        valid "$spec" || { echo "Ungültige Anzeige-Einstellung: $spec" >&2; exit 2; }
        IFS=: read -r name state pri mode rate rot x y <<EOF
$spec
EOF
        if [ "$state" = off ]; then args="$args --output $name --off"
        else
            args="$args --output $name --mode $mode --rate $rate --rotate $rot --pos ${x}x${y}"
            [ "$pri" = 1 ] && args="$args --primary"
        fi
    done
    [ -n "$args" ] || exit 2
    # shellcheck disable=SC2086 # every word was validated above
    xrandr $args
}

case "${1:-}" in
    list) list ;;
    apply) shift; apply "$@" ;;
    save)
        shift; for spec in "$@"; do valid "$spec" || exit 2; done
        mkdir -p "${conf%/*}"; [ ! -L "$conf" ] || exit 1
        tmp=$(mktemp "${conf%/*}/.monitors.XXXXXX") && printf '%s\n' "$@" > "$tmp" && mv -f "$tmp" "$conf"
        echo 'Gespeichert: wird beim nächsten Login verwendet.' ;;
    restore)
        [ -f "$conf" ] && [ ! -L "$conf" ] || exit 3
        present=$(list | cut -f1)
        specs=''
        while IFS= read -r spec; do
            valid "$spec" || continue
            printf '%s\n' "$present" | grep -qx "${spec%%:*}" || continue
            specs="$specs $spec"
        done < "$conf"
        [ -n "$specs" ] || exit 3
        # shellcheck disable=SC2086
        apply $specs ;;
    *) echo 'Aufruf: display-settings.sh list|apply|save|restore' >&2; exit 2 ;;
esac
