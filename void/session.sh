#!/bin/sh
# Own only this session's children; never kill another Quickshell instance.
data=$HOME/.local/share/dwm-void
"$data/dwm" &
wm=$!
panel=''
if command -v quickshell >/dev/null 2>&1; then
    quickshell --path "$data/quickshell/shell.qml" > "$data/quickshell.log" 2>&1 &
    panel=$!
fi
cleanup() {
    [ -z "$panel" ] || kill "$panel" 2>/dev/null || :
    kill "$wm" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
wait "$wm"
