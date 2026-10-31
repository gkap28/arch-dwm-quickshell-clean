#!/bin/sh
set -u
data=$HOME/.local/share/dwm-void
case "${1:-}" in
    terminal) exec alacritty ;;
    hotkeys) exec alacritty -e sh -c 'exec "${EDITOR:-vi}" "$HOME/.local/share/dwm-void/config/hotkeys.toml"' ;;
    files) exec thunar ;;
    displays) exec arandr ;;
    volume) exec pavucontrol ;;
    network) exec alacritty -e nmtui ;;
    wallpaper) exec sh "$data/wallpaper.sh" ;;
    power) exec "$data/power-menu" ;;
    apps)
        export DWM_VOID_LAUNCHER_X=${2:-0} DWM_VOID_LAUNCHER_Y=${3:-0}
        exec quickshell --path "$data/quickshell/launcher.qml"
        ;;
    *) echo 'Unbekannte Aktion.' >&2; exit 1 ;;
esac
