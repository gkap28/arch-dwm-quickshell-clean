#!/bin/sh
# Own only this session's children; never kill another shell or compositor.
data=$HOME/.local/share/dwm-void
"$data/dwm" &
wm=$!
panel=''
compositor=''
if command -v picom >/dev/null 2>&1 && [ ! -L "$data/picom.log" ]; then
    picom > "$data/picom.log" 2>&1 &
    compositor=$!
fi
if command -v quickshell >/dev/null 2>&1; then
    quickshell --path "$data/quickshell/shell.qml" > "$data/quickshell.log" 2>&1 &
    panel=$!
fi
cleanup() {
    [ -z "$panel" ] || kill "$panel" 2>/dev/null || :
    [ -z "$compositor" ] || kill "$compositor" 2>/dev/null || :
    kill "$wm" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
wait "$wm"
