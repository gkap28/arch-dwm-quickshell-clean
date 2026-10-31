# Georgs Void-Grundlage

Getrennter Einstieg vom festen Ausgangsstand 1a86bbcbb9077984df0848061f6c41bd87282503. Hauptzweig, Makefile, install.sh und Originalquellen bleiben unveraendert. Die heutigen Originaldokumente nennen Fedora; dies bescheinigt keine Arch-Kompatibilitaet des Gesamtprojekts.

## Auf deinem vorbereiteten Void, ohne sudo

```sh
git clone --branch void-starter --single-branch https://github.com/gkap28/arch-dwm-quickshell-clean.git dwm-void
cd dwm-void
sh void/start.sh
```

Der letzte Befehl prueft die Voraussetzungen, uebersetzt und richtet die Grundlage nur fuer dein Benutzerkonto ein und startet den Desktop mit startx. Git clone allein startet nichts. KEIN sudo make install und KEIN install.sh verwenden.

Du installierst alle Pakete selbst. Benoetigt: cc, make, pkg-config, Xorg mit startx, xsetroot (Void-Paket xsetroot), Alacritty und eine funktionierende Schrift. Benoetigte pkg-config-Module: x11 xft xinerama xrender imlib2 x11-xcb xcb xcb-res fontconfig freetype2. Auf Void heissen zwei deiner genannten Pakete libXinerama-devel und harfbuzz-devel. Quickshell und HarfBuzz sind fuer diesen ersten Einstieg nicht erforderlich. Deine Grafikkarte muss mit Xorg funktionieren.

Nur pruefen: sh void/start.sh --check
Nur vorbereiten: sh void/start.sh --install
Spaeter aus der Konsole erneut starten:
```sh
startx "$HOME/.local/share/dwm-void/xinitrc" -- -nolisten tcp
```

## Der Desktop

Oben eine schmale Leiste: links die Arbeitsflaechen, rechts WLAN, Akku (falls vorhanden) und Uhrzeit, alle 30 Sekunden frisch. Noch ohne Kontrollzentrum, Hintergrundbild und automatischen Programmstart. Super+X oder Super+Return: Alacritty. Brave startest du dort mit dem bei dir installierten Brave-Befehl. Super+J/K: Fenster wechseln; Super+1 bis 9: Arbeitsflaechen wechseln; Super+Shift+C: Fenster schliessen; Super+Shift+Q: zur Konsole zurueck.

## Sicherheit

Nur ~/.local/share/dwm-void wird beschrieben: dwm, xinitrc, status.sh (Leisten-Helfer) und config mit hotkeys.toml, themes.toml und window-rules.toml. Vorhandene TOML-Dateien bleiben erhalten; der temporaere Bauordner wird entfernt. ~/.config, ~/.xinitrc, /usr, Dienste und Pakete werden nicht angefasst. Xorg/startx kann seine eigenen normalen Sitzungsdateien anlegen. In einer privaten Baukopie werden die Original-Start-/Stop-Routinen und der automatische Themen-Helfer abgeschaltet und die TOML-Pfade umgeleitet. Der originale Quelltext bleibt unveraendert.

## Pruefstand

Sieben Tests in einer getrennten Linux-Testumgebung erfolgreich: drei Sicherheitspruefungen sowie vier Starterpruefungen inklusive sichtbarer X11-Leiste am oberen Rand, positiver Leistenhoehe und Statuswechsel. Ein Bild bestaetigt Arbeitsflaeche und Status rechts. Der Fenstertest verwendete Xterm als sichtbaren Ersatz und bestaetigte den Aufruf des Alacritty-Befehls. Georg hat Desktop, Alacritty und Brave auf Void bereits gestartet; die korrigierte Leiste muss er noch auf seiner Hardware bestaetigen. Quickshell, Ton und Kontrollzentrum sind noch nicht portiert.
