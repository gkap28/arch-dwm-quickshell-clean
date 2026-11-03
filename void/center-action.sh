#!/bin/sh
# Explicit, bounded user actions. No eval, global kills, system services or sudo.
set -eu
data=$HOME/.local/share/dwm-void
for p in "$HOME/.local" "$HOME/.local/share" "$data" "$data/quickshell" "$data/bar-bridge" "$data/control-action.sh" "$data/wallpaper.sh" "$data/updates.sh"; do
    [ ! -L "$p" ] || { echo 'Unsicherer Aktionspfad.' >&2; exit 1; }
done
case "${1:-}" in
    reload-quickshell)
        [ -f "$data/quickshell/shell.qml" ] && [ ! -L "$data/quickshell/shell.qml" ] || exit 1
        pkill -x quickshell; sleep 1; quickshell --path "$data/quickshell/shell.qml" >/dev/null 2>&1 &
        echo 'Neuladen der Void-Leiste angefordert.'; exit ;;
    restart-picom) pkill -x picom; sleep 1; picom >/dev/null 2>&1 & echo 'Picom neu gestartet.'; exit ;;
    restart-networkmanager) exec alacritty -e sh -c 'sudo sv restart NetworkManager; echo; echo Enter zum Schliessen; read answer' ;;
    dpms-*) sh "$data/power-dpms.sh" set "${1#dpms-}"; echo "Bildschirm-Timeout gesetzt."; exit ;;
    reload-dwm) "$data/bar-bridge" reload; echo 'Neuladen der dwm-Einstellungen angefordert.'; exit ;;
    displays) exec arandr ;;
    input) exec alacritty -e sh -c 'setxkbmap -query; xinput list; printf "\nEnter zum Schließen\n"; read answer' ;;
    network) if command -v nm-connection-editor >/dev/null 2>&1; then exec nm-connection-editor; else exec alacritty -e nmtui; fi ;;
    bluetooth) if command -v blueman-manager >/dev/null 2>&1; then exec blueman-manager; else exec alacritty -e bluetoothctl; fi ;;
    audio) exec pavucontrol ;;
    hotkeys) exec sh "$data/control-action.sh" hotkeys ;;
    appearance) exec nwg-look ;;
    wallpaper) exec sh "$data/wallpaper.sh" ;;
    xbps|flatpak) exec sh "$data/updates.sh" "$1" ;;
    defaults) exec alacritty -e sh -c 'xdg-settings get default-web-browser; xdg-mime query default inode/directory; printf "\nEnter zum Schließen\n"; read answer' ;;
    diagnostics) exec alacritty -e sh -c 'sh "$HOME/.local/share/dwm-void/system-info.sh"; printf "\nEnter zum Schließen\n"; read answer' ;;
    *) echo 'Diese Aktion ist nicht verfügbar.' >&2; exit 2 ;;
esac