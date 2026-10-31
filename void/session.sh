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
    if [ -r "$data/quickshell/shell.qml" ] && [ -r "$data/quickshell/StatusModules.qml" ]; then
        quickshell --path "$data/quickshell/shell.qml" > "$data/quickshell.log" 2>&1 &
        panel=$!
    else
        # Keep the native Nord bar instead of a half-loaded panel; say why.
        echo 'Leiste: Quickshell-Dateien unvollstaendig. Bitte: git pull && sh void/start.sh --install' > "$data/quickshell.log" 2>&1
    fi
fi
cleanup() {
    [ -z "$panel" ] || kill "$panel" 2>/dev/null || :
    [ -z "$compositor" ] || kill "$compositor" 2>/dev/null || :
    kill "$wm" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
wait "$wm"