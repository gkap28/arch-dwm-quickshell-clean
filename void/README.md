# Georgs Void-Grundlage

Getrennter Einstieg vom Ausgangsstand 1a86bbcbb9077984df0848061f6c41bd87282503. Hauptzweig, Makefile, install.sh und Originalquellen bleiben unveraendert.

## Auf vorbereitetem Void, ohne sudo

```sh
git clone --branch void-starter --single-branch https://github.com/gkap28/arch-dwm-quickshell-clean.git dwm-void
cd dwm-void
sh void/start.sh
```

Kein sudo make install und kein install.sh. Alle Pakete installierst du selbst. Benoetigt: cc, make, pkg-config, awk, Xorg/startx, xsetroot, Alacritty, eine funktionierende Schrift. pkg-config-Module: x11 xft xinerama xrender imlib2 x11-xcb xcb xcb-res fontconfig freetype2. Quickshell ist noch nicht erforderlich.

Nur pruefen: sh void/start.sh --check
Nur einrichten: sh void/start.sh --install

## Desktop

Jeder Monitor zeigt Arbeitsflaechen 1-9, auch leere. Super+1 bis 9 wechselt nur auf dem Monitor mit dem Mauszeiger/Fokus; der andere Monitor bleibt auf seiner Arbeitsflaeche. Datum und Uhrzeit erscheinen mittig auf beiden Leisten, mit WLAN/Akku falls vorhanden. Aktualisierung alle 30 Sekunden.

Ein vorhandenes Bild aus ~/Pictures/backgrounds wird mit feh auf beiden Monitoren gesetzt. Benoetigt das selbst installierte Void-Paket feh. Kein Download, keine ~/.fehbg. Fehlendes feh oder fehlende Bilder verhindern den Start nicht. Unterschiedliche Bilder je Monitor folgen erst beim Kontrollzentrum.

## Programmtasten

Nach git pull: sh void/update-hotkeys.sh.
Super+Q: Fenster schliessen. Super+Shift+Return: Thunar. Super+B: Brave. Super+Return und Super+X: Alacritty. Super+Shift+Q: Konsole.
Die erste vorherige Tastendatei wird als hotkeys.toml.before-app-keys gesichert. Unverwandte Tasten bleiben erhalten; automatische Neuladung ohne Neustart.

## Monitoranordnung

HDMI-A-0: 2560x1080 links bei 0x0. DisplayPort-2: 1920x1080 rechts bei 2560x0. monitors.sh stellt dies vor dwm wieder her. Fehlende Ausgaenge und xrandr-Fehler blockieren den Start nicht.

## Updates

Im bestehenden Klon: git pull; sh void/start.sh --install. Offene Arbeiten speichern, Super+Shift+Q, dann aus der Konsole sh void/start.sh. Bei automatischem startx startet der Desktop sofort neu.

## Sicherheit

Nur ~/.local/share/dwm-void wird beschrieben: dwm, xinitrc, status.sh, monitors.sh, wallpaper.sh und config. Vorhandene TOML-Dateien bleiben erhalten. ~/.config, ~/.xinitrc, /usr, Dienste und Pakete bleiben unangetastet. Anpassungen fuer Leiste und Start erfolgen ausschliesslich in einer temporaeren Baukopie. Xorg/startx kann seine eigenen Sitzungsdateien anlegen.

## Pruefstand

Sicherheits-, Hintergrund- und Startertests erfolgreich. Zwei Xinerama-Monitore mit Georgs Groessen wurden unter Xvfb nachgebildet: Arbeitsflaechen 1-9 wechseln unabhaengig; ein Fenster auf dem anderen Monitor bleibt sichtbar. Beide Leisten aktualisieren ohne Fokuswechsel; Bilder bestaetigen 1-9 und mittigen Status. Xterm ersetzte Alacritty im Fenstertest. Dies ersetzt keine Hardwarepruefung. Georg bestaetigte Desktop, Leiste und Monitoranordnung nach Neustart auf Void. Neue Leisten und Hintergrund sind dort noch zu bestaetigen. Quickshell, Ton und Kontrollzentrum sind noch nicht portiert.

## Ton

Void startet PipeWire nicht von selbst. Ist pipewire installiert und laeuft fuer dich noch nicht, startet die Sitzung pipewire, dazu wireplumber (wenn PipeWire es nicht schon selbst startet) und pipewire-pulse (falls installiert). Beim Abmelden endet nur dieser eigene Ton. Ein schon laufendes PipeWire bleibt unberuehrt. Meldungen: ~/.local/share/dwm-void/pipewire.log. Keine Systemdateien, keine Dienste, nichts in ~/.config. RTKit-Warnungen sind harmlos.
