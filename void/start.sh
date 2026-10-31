#!/bin/sh
# Isolated Void entry point. Never calls the upstream installer.
set -eu
mode=${1:---start}
case "$mode" in --check|--install|--start) ;; *) echo 'Aufruf: sh void/start.sh [--check|--install|--start]' >&2; exit 2 ;; esac
[ "$(id -u)" -ne 0 ] || { echo 'Bitte als normaler Benutzer, ohne sudo starten.' >&2; exit 1; }
[ -r /etc/os-release ] || { echo '/etc/os-release fehlt.' >&2; exit 1; }
. /etc/os-release
[ "${ID:-}" = void ] || { echo 'Dieser getrennte Einstieg ist nur fuer Void Linux.' >&2; exit 1; }
repo=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
data=$HOME/.local/share/dwm-void
for cmd in cc make pkg-config startx alacritty xsetroot awk; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Fehlt: $cmd" >&2; exit 1; }
done
modules='x11 xft xinerama xrender imlib2 x11-xcb xcb xcb-res fontconfig freetype2'
for module in $modules; do
    pkg-config --exists "$module" || { echo "Fehlende Entwicklungsbibliothek: $module" >&2; exit 1; }
done
[ "$mode" != --check ] || { echo 'Voraussetzungen vorhanden. Keine Dateien installiert.'; exit 0; }
if [ "$mode" = --start ] && [ -n "${DISPLAY:-}" ]; then
    echo 'Bereits eine grafische Sitzung offen. Bitte aus der Konsole starten.' >&2
    exit 1
fi
# Reject symlinks on all managed paths before writing anything.
for path in "$HOME/.local" "$HOME/.local/share" "$data" "$data/config" "$data/dwm" "$data/dwm.new" "$data/xinitrc" "$data/status.sh" "$data/monitors.sh" "$data/wallpaper.sh" "$data/power-menu" "$data/power-action.sh" "$data/control-action.sh"; do
    [ ! -L "$path" ] || { echo "Abbruch: symbolischer Link: $path" >&2; exit 1; }
done
mkdir -p "$data/config"
build=$(mktemp -d "$data/build.XXXXXXXX")
trap 'rm -rf -- "$build"' EXIT HUP INT TERM
for file in dwm.c drw.c drw.h util.c util.h tomlparser.c tomlparser.h config.def.h config.mk; do
    cp "$repo/$file" "$build/$file"
done
# Adapt a private build copy only; upstream C and Arch/Fedora entry points stay intact.
[ "$(grep -c '^runautoscript(const char \*script)$' "$build/dwm.c")" = 1 ] || { echo 'Quellstand geaendert: Startanpassung pruefen.' >&2; exit 1; }
sed '/^runautoscript(const char \*script)$/,+1!b; /^{$/a\
#ifdef DWM_VOID_MINIMAL\
\t(void)script;\
\treturn 0;\
#endif
' "$build/dwm.c" > "$build/dwm.new"
sed 's|".config/dwm-titus"|".local/share/dwm-void/config"|g; s|".local/share/dwm-titus/config"|".local/share/dwm-void/config"|g; /Spawn theme-apply script asynchronously/i\
#ifdef DWM_VOID_MINIMAL\
\treturn;\
#endif' "$build/dwm.new" > "$build/dwm.c"
# Upstream delegates its bar to Quickshell. Restore the native bar ONLY here.
for marker in 'The Quickshell panel handles drawing; the dwm bar is unused.' 'The external panel creates its own windows; skip dwm bar creation.' 'bh = 0; /\* Quickshell provides the panel. \*/' '^scanaltbars(void)$'; do
    [ "$(grep -c "$marker" "$build/dwm.c")" = 1 ] || { echo 'Quellstand geaendert: Leistenanpassung pruefen.' >&2; exit 1; }
done
sed '/The Quickshell panel handles drawing; the dwm bar is unused\./{N;d;}; /The external panel creates its own windows; skip dwm bar creation\./{N;d;}; s/bh = 0; \/\* Quickshell provides the panel\. \*\//bh = drw->fonts->h + 2; \/\* Native Void bar height. \*\//; /^scanaltbars(void)$/,+1!b; /^{$/a\
#ifdef DWM_VOID_MINIMAL\
\treturn;\
#endif
' "$build/dwm.c" > "$build/dwm.new"
mv "$build/dwm.new" "$build/dwm.c"
awk -f "$repo/void/bar.awk" "$build/dwm.c" > "$build/dwm.new"
mv "$build/dwm.new" "$build/dwm.c"
sed 's/MesloLGS Nerd Font Mono/monospace/g' "$build/config.def.h" > "$build/config.h"
cp "$repo/void/power-menu.c" "$build/power-menu.c"
for header in logo.h logo-draw.h popup-grab.h; do cp "$repo/void/$header" "$build/$header"; done
# No upstream Makefile install target is involved.
cat > "$build/Makefile" <<'MAKE'
include config.mk
SRC = dwm.c drw.c util.c tomlparser.c
all:
	$(CC) $(CPPFLAGS) -DDWM_VOID_MINIMAL $(CFLAGS) -o dwm $(SRC) $(LDFLAGS) $(LDLIBS)
	$(CC) $(CPPFLAGS) $(CFLAGS) -o power-menu power-menu.c $(LDFLAGS) $(LDLIBS)
MAKE
make -C "$build"
for file in hotkeys.toml themes.toml window-rules.toml; do
    target=$data/config/$file
    [ ! -L "$target" ] || { echo "Abbruch: symbolischer Link: $target" >&2; exit 1; }
    if [ ! -e "$target" ]; then
        case "$file" in
            hotkeys.toml) (set -C; cat > "$target" <<'HOTKEYS'
[vars]
terminal = "alacritty"
keys = [
 { mod="SUPER", key="x", func="spawn", exec=["$terminal"] },
 { mod="SUPER", key="Return", func="spawn", exec=["$terminal"] },
 { mod="SUPER", key="j", func="focusstack", i=1 },
 { mod="SUPER", key="k", func="focusstack", i=-1 },
 { mod="SUPER", key="h", func="setmfact", f=-0.05 },
 { mod="SUPER", key="l", func="setmfact", f=0.05 },
 { mod="SUPER", key="space", func="setlayout", layout_idx=0 },
 { mod="SUPER SHIFT", key="space", func="togglefloating" },
 { mod="SUPER", key="f", func="fullscreen" },
 { mod="SUPER SHIFT", key="c", func="killclient" },
 { mod="SUPER SHIFT", key="q", func="quit" },
 { mod="SUPER", key="1", func="view", ui=1 },
 { mod="SUPER", key="2", func="view", ui=2 },
 { mod="SUPER", key="3", func="view", ui=4 },
 { mod="SUPER", key="4", func="view", ui=8 },
 { mod="SUPER", key="5", func="view", ui=16 },
 { mod="SUPER", key="6", func="view", ui=32 },
 { mod="SUPER", key="7", func="view", ui=64 },
 { mod="SUPER", key="8", func="view", ui=128 },
 { mod="SUPER", key="9", func="view", ui=256 },
 { mod="SUPER SHIFT", key="1", func="tag", ui=1 },
 { mod="SUPER SHIFT", key="2", func="tag", ui=2 },
 { mod="SUPER SHIFT", key="3", func="tag", ui=4 }
]
HOTKEYS
) ;;
            themes.toml) (set -C; cat > "$target" <<'THEME'
[appearance]
borderpx = 2
[colors]
normbordercolor = "#3B4252"
normbgcolor = "#2E3440"
normfgcolor = "#D8DEE9"
selbordercolor = "#88C0D0"
selbgcolor = "#434C5E"
selfgcolor = "#ECEFF4"
THEME
) ;;
            window-rules.toml) (set -C; cat > "$target" <<'RULES'
rules = [
 { class="Alacritty", isterminal=1, noswallow=1 }
]
RULES
) ;;
        esac
    fi
done
install -m 755 "$build/dwm" "$data/dwm.new"
mv -f "$data/dwm.new" "$data/dwm"
cat > "$build/xinitrc" <<'SESSION'
#!/bin/sh
set -eu
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=dwm
export DESKTOP_SESSION=dwm-void
# Restore the confirmed monitor layout before dwm reads screen geometry.
sh "$HOME/.local/share/dwm-void/monitors.sh"
sh "$HOME/.local/share/dwm-void/wallpaper.sh"
# Statuszeile fuer die Leiste (Uhrzeit, WLAN, Akku) im Hintergrund.
"$HOME/.local/share/dwm-void/status.sh" &
# Optional session bus; no systemd services or upstream autostart.
if command -v dbus-run-session >/dev/null 2>&1 && [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    exec dbus-run-session -- "$HOME/.local/share/dwm-void/dwm"
fi
exec "$HOME/.local/share/dwm-void/dwm"
SESSION
install -m 755 "$build/xinitrc" "$data/xinitrc"
install -m 755 "$repo/void/status.sh" "$data/status.sh"
install -m 755 "$repo/void/monitors.sh" "$data/monitors.sh"
install -m 755 "$repo/void/wallpaper.sh" "$data/wallpaper.sh"
install -m 755 "$build/power-menu" "$data/power-menu"
install -m 755 "$repo/void/power-action.sh" "$data/power-action.sh"
install -m 755 "$repo/void/control-action.sh" "$data/control-action.sh"
echo 'Void-Grundlage bereit. Super+X: Alacritty. Super+Shift+Q: zurueck zur Konsole.'
[ "$mode" != --install ] || exit 0
[ -z "${DISPLAY:-}" ] || { echo 'Bereits eine grafische Sitzung offen. Bitte aus der Konsole starten.' >&2; exit 1; }
rm -rf -- "$build"
trap - EXIT HUP INT TERM
exec startx "$data/xinitrc" -- -nolisten tcp
