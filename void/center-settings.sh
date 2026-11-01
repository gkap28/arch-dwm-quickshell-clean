#!/bin/sh
# Validated private preferences. Never source configuration as shell code.
set -eu
data=$HOME/.local/share/dwm-void
file=$data/config/center.conf
for p in "$HOME/.local" "$HOME/.local/share" "$data" "$data/config" "$file"; do
    [ ! -L "$p" ] || { echo 'Unsicherer Einstellungspfad.' >&2; exit 1; }
done
[ ! -e "$file" ] || [ -f "$file" ] || exit 1
if [ -d "$data/config" ]; then
    [ "$(stat -c %u "$data/config")" = "$(id -u)" ] || exit 1
    case "$(stat -c %a "$data/config")" in *[2367][0-7]|*[0-7][2367]) echo 'Einstellungsordner ist fremd beschreibbar.' >&2; exit 1;; esac
fi
valid() {
    case "$1:$2" in
        power:0|power:1|volume:0|volume:1|network:0|network:1|layout:0|layout:1|seconds:0|seconds:1|timeout:0|timeout:5|timeout:10|timeout:15|timeout:30|timeout:45) return 0 ;;
        *) return 1 ;;
    esac
}
read_values() {
    power=1 volume=1 network=1 layout=1 seconds=0 timeout=0
    if [ -f "$file" ]; then
        while IFS='=' read -r key value; do
            valid "$key" "$value" || continue
            case "$key" in power) power=$value;; volume) volume=$value;; network) network=$value;; layout) layout=$value;; seconds) seconds=$value;; timeout) timeout=$value;; esac
        done < "$file"
    fi
}
print_values() { printf 'power=%s\nvolume=%s\nnetwork=%s\nlayout=%s\nseconds=%s\ntimeout=%s\n' "$power" "$volume" "$network" "$layout" "$seconds" "$timeout"; }
case "${1:-read}" in
    read) read_values; print_values; exit ;;
    set) [ "$#" = 3 ] && valid "$2" "$3" || exit 2 ;;
    *) exit 2 ;;
esac
if [ "$2" = timeout ] && [ "$3" != 0 ]; then
    command -v slock >/dev/null 2>&1 || command -v i3lock >/dev/null 2>&1 || { echo 'Sperrprogramm fehlt: slock oder i3lock erforderlich.' >&2; exit 1; }
fi
mkdir -p "$data/config"
lock=$data/config/.center-lock
[ ! -L "$lock" ] || exit 1
mkdir "$lock" 2>/dev/null || { echo 'Einstellungen werden gerade gespeichert.' >&2; exit 1; }
temp=''
trap '[ -z "$temp" ] || rm -f "$temp"; rmdir "$lock" 2>/dev/null || :' EXIT HUP INT TERM
read_values
case "$2" in power) power=$3;; volume) volume=$3;; network) network=$3;; layout) layout=$3;; seconds) seconds=$3;; timeout) timeout=$3;; esac
umask 077
temp=$(mktemp "$data/config/.center.XXXXXXXX")
print_values > "$temp"
mv -f "$temp" "$file"
temp=''
print_values