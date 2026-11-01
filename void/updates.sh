#!/bin/sh
# Status never refreshes repositories or applies updates. Explicit actions open a terminal.
set -u
export LC_ALL=C
case "${1:-status}" in
    xbps)
        command -v alacritty >/dev/null 2>&1 || exit 1
        [ -x /usr/bin/xbps-install ] || exit 1
        exec alacritty -e sh -c 'sudo /usr/bin/xbps-install -Su; result=$?; printf "\nFertig (Status %s). Enter zum Schliessen.\n" "$result"; read -r answer' ;;
    flatpak)
        command -v flatpak >/dev/null 2>&1 || exit 1
        command -v alacritty >/dev/null 2>&1 || exit 1
        exec alacritty -e sh -c 'flatpak update --user; user_result=$?; flatpak update --system; system_result=$?; printf "\nFertig: Benutzer %s, System %s. Enter zum Schliessen.\n" "$user_result" "$system_result"; read -r answer' ;;
    status) ;;
    *) exit 1 ;;
esac
xbps=-1
flatpak_count=-1
if command -v timeout >/dev/null 2>&1; then
    if command -v xbps-install >/dev/null 2>&1; then
        if rows=$(timeout 30 xbps-install -Mun 2>/dev/null); then
            xbps=$(printf '%s\n' "$rows" | awk 'NF {n++} END {print n+0}')
        fi
    fi
    if command -v flatpak >/dev/null 2>&1; then
        if user_rows=$(timeout 30 flatpak remote-ls --updates --user --columns=ref 2>/dev/null) && system_rows=$(timeout 30 flatpak remote-ls --updates --system --columns=ref 2>/dev/null); then
            flatpak_count=$(printf '%s\n%s\n' "$user_rows" "$system_rows" | awk 'NF {n++} END {print n+0}')
        fi
    fi
fi
printf '%s\t%s\n' "$xbps" "$flatpak_count"