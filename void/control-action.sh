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
    apps|system-info)
        export DWM_VOID_LAUNCHER_X=${2:-0} DWM_VOID_LAUNCHER_Y=${3:-0}
        # dwm places the launcher on its focused monitor: focus the clicked one first.
        "$data/bar-bridge" focus "$DWM_VOID_LAUNCHER_X" "$DWM_VOID_LAUNCHER_Y" 2>/dev/null || :
        if [ "$1" = system-info ]; then exec quickshell --path "$data/quickshell/system-info.qml"; fi
        exec quickshell --path "$data/quickshell/launcher.qml"
        ;;
    *) echo 'Unbekannte Aktion.' >&2; exit 1 ;;
esac