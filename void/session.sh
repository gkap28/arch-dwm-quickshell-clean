#!/bin/sh
# Own only this session's children; never kill another shell, compositor or sound server.
data=$HOME/.local/share/dwm-void
"$data/dwm" &
wm=$!
panel=''
compositor=''
sound=''
running() {
    command -v pgrep >/dev/null 2>&1 && pgrep -u "$(id -u)" -x "$1" >/dev/null 2>&1
}
await() {
    # Up to about three seconds; never block the session start.
    tries=0
    while [ "$tries" -lt 30 ]; do
        eval "$1" && return 0
        sleep .1
        tries=$((tries + 1))
    done
    return 1
}
# Void has no user service manager: start PipeWire here unless this user already has one.
if command -v pipewire >/dev/null 2>&1 && [ ! -L "$data/pipewire.log" ]; then
    if [ -z "${XDG_RUNTIME_DIR:-}" ] || [ ! -d "$XDG_RUNTIME_DIR" ]; then
        echo 'Ton: XDG_RUNTIME_DIR fehlt, PipeWire nicht gestartet (elogind angemeldet?)' > "$data/pipewire.log"
    elif ! running pipewire; then
        pipewire > "$data/pipewire.log" 2>&1 &
        sound="$!"
        await '[ -S "$XDG_RUNTIME_DIR/pipewire-0" ]' || :
        # Some setups let PipeWire launch these itself; add only what is missing.
        if command -v wireplumber >/dev/null 2>&1 && ! await 'running wireplumber'; then
            wireplumber >> "$data/pipewire.log" 2>&1 &
            sound="$sound $!"
        fi
        if command -v pipewire-pulse >/dev/null 2>&1 && ! running pipewire-pulse && [ ! -S "$XDG_RUNTIME_DIR/pulse/native" ]; then
            pipewire-pulse >> "$data/pipewire.log" 2>&1 &
            sound="$sound $!"
        fi
    fi
fi
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
    for pid in $sound; do kill "$pid" 2>/dev/null || :; done
    kill "$wm" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
wait "$wm"
