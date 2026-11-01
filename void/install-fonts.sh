#!/bin/sh
# Requested Titus fonts, loaded only by the isolated Quickshell configuration.
set -eu
data=$HOME/.local/share/dwm-void
fonts=$data/quickshell/fonts
for path in "$HOME/.local" "$HOME/.local/share" "$data" "$data/quickshell" "$fonts" "$fonts/Meslo-Regular.ttf" "$fonts/Meslo-Bold.ttf"; do
    [ ! -L "$path" ] || { echo "Abbruch: symbolischer Link: $path" >&2; exit 1; }
done
mkdir -p "$fonts"
command -v curl >/dev/null 2>&1 || { echo 'Schrift: curl fehlt.' >&2; exit 1; }
stage=$(mktemp -d "$data/font-download.XXXXXXXX")
trap 'rm -rf -- "$stage"' EXIT HUP INT TERM
base=https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v3.4.0/patched-fonts/Meslo/S
for style in Regular Bold; do
    [ "$style" != Regular ] || checksum=3cb52e923ca3981cecca9ea7307186e424e8521cbc5643fd0b5b5b1d7daa53d9
    [ "$style" != Bold ] || checksum=f7124d4cbd6465f261d6b4dca25070084971a525002c0ae913f5f74b84ff1f6d
    target=$fonts/Meslo-$style.ttf
    if [ -f "$target" ] && printf '%s  %s\n' "$checksum" "$target" | sha256sum -c - >/dev/null 2>&1; then continue; fi
    curl --fail --location --silent --show-error --connect-timeout 10 --max-time 90 "$base/$style/MesloLGSNerdFontMono-$style.ttf" -o "$stage/$style.ttf"
    printf '%s  %s\n' "$checksum" "$stage/$style.ttf" | sha256sum -c - >/dev/null
    install -m 644 "$stage/$style.ttf" "$target"
done