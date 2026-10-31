#!/bin/sh
# Update only the requested keys, preserving all other single-line bindings.
set -eu
[ "$(id -u)" -ne 0 ] || { echo 'Ohne sudo ausfuehren.' >&2; exit 1; }
data=$HOME/.local/share/dwm-void
file=$data/config/hotkeys.toml
for path in "$HOME/.local" "$HOME/.local/share" "$data" "$data/config" "$file" "$file.before-app-keys"; do
    [ ! -L "$path" ] || { echo 'Abbruch: symbolischer Link.' >&2; exit 1; }
done
[ -f "$file" ] || { echo 'Zuerst sh void/start.sh --install ausfuehren.' >&2; exit 1; }
temp=$(mktemp "$data/hotkeys.XXXXXXXX")
trap 'rm -f "$temp"' EXIT HUP INT TERM
awk '
/^[[:space:]]*keys[[:space:]]*=[[:space:]]*\[[[:space:]]*$/ { inside=1; starts++; print; next }
inside && /^[[:space:]]*\][[:space:]]*$/ {
 print " { mod=\"SUPER\", key=\"q\", func=\"killclient\" },"
 print " { mod=\"SUPER SHIFT\", key=\"Return\", func=\"spawn\", exec=[\"thunar\"] },"
 print " { mod=\"SUPER\", key=\"b\", func=\"spawn\", cmd=\"command -v brave >/dev/null 2>&1 && exec brave; command -v brave-browser >/dev/null 2>&1 && exec brave-browser; command -v brave-browser-stable >/dev/null 2>&1 && exec brave-browser-stable\" },"
 print " { mod=\"SUPER\", key=\"Return\", func=\"spawn\", exec=[\"alacritty\"] },"
 print; inside=0; ends++; next
}
inside && /mod[[:space:]]*=[[:space:]]*"SUPER"/ && /key[[:space:]]*=[[:space:]]*"(q|b|Return)"/ { next }
inside && /mod[[:space:]]*=[[:space:]]*"SUPER SHIFT"/ && /key[[:space:]]*=[[:space:]]*"Return"/ { next }
inside && /^[[:space:]]*\{/ && !/\}[[:space:]]*,?[[:space:]]*$/ { bad=1 }
{ if (inside && /^[[:space:]]*\{.*\}[[:space:]]*$/) sub(/\}[[:space:]]*$/, "},"); print }
END { if (starts != 1 || ends != 1 || bad) exit 1 }
' "$file" > "$temp" || { echo 'Ungewoehnliche Tastendatei; unveraendert gelassen.' >&2; exit 1; }
if [ ! -e "$file.before-app-keys" ]; then (set -C; cat "$file" > "$file.before-app-keys"); fi
cat "$temp" > "$file"
echo 'Tasten eingerichtet: Super+Q schliessen; Super+Shift+Return Thunar; Super+B Brave; Super+Return Alacritty.'