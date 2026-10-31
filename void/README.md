# Georgs Void-Grundlage

Getrennter Einstieg vom festen Ausgangsstand 1a86bbcbb9077984df0848061f6c41bd87282503. Hauptzweig, Makefile, install.sh und Originalquellen bleiben unveraendert. Die heutigen Originaldokumente nennen Fedora; dies bescheinigt keine Arch-Kompatibilitaet des Gesamtprojekts.

## Auf deinem vorbereiteten Void, ohne sudo

```sh
git clone --branch void-starter --single-branch https://github.com/gkap28/arch-dwm-quickshell-clean.git dwm-void
cd dwm-void
sh void/start.sh
```

Der letzte Befehl prueft die Voraussetzungen, uebersetzt und richtet die Grundlage nur fuer dein Benutzerkonto ein und startet den Desktop mit startx. Git clone allein startet nichts. KEIN sudo make install und KEIN install.sh verwenden.

Du installierst alle Pakete selbst. Benoetigt: cc, make, pkg-config, Xorg mit startx, Alacritty und eine funktionierende Schrift. Benoetigte pkg-config-Module: x11 xft xinerama xrender imlib2 x11-xcb xcb xcb-res fontconfig freetype2. Auf Void heissen zwei deiner genannten Pakete libXinerama-devel und harfbuzz-devel. Quickshell und HarfBuzz sind fuer diesen ersten Einstieg nicht erforderlich. Deine Grafikkarte muss mit Xorg funktionieren.

Nur pruefen: sh void/start.sh --check
Nur vorbereiten: sh void/start.sh --install
Spaeter aus der Konsole erneut starten:
```sh
startx "$HOME/.local/share/dwm-void/xinitrc" -- -nolisten tcp
```

## Erster Desktop

Bewusst ohne Leiste, Kontrollzentrum, Hintergrundbild und automatischen Programmstart. Ein leerer Hintergrund ist normal. Super+X oder Super+Return: Alacritty. Brave startest du dort mit dem bei dir installierten Brave-Befehl. Super+J/K: Fenster wechseln; Super+1 bis 9: Arbeitsflaechen wechseln; Super+Shift+C: Fenster schliessen; Super+Shift+Q: zur Konsole zurueck.

## Sicherheit

Nur ~/.local/share/dwm-void wird beschrieben: dwm, xinitrc und config mit hotkeys.toml, themes.toml und window-rules.toml. Vorhandene TOML-Dateien bleiben erhalten; der temporaere Bauordner wird entfernt. ~/.config, ~/.xinitrc, /usr, Dienste und Pakete werden nicht angefasst. Xorg/startx kann seine eigenen normalen Sitzungsdateien anlegen. In einer privaten Baukopie werden die Original-Start-/Stop-Routinen und der automatische Themen-Helfer abgeschaltet und die TOML-Pfade umgeleitet. Der originale Quelltext bleibt unveraendert.

## Pruefstand

Vier Tests in einer anderen Linux-Testumgebung erfolgreich: Nicht-Void abweisen, vorhandene Dateien und Originalquellen erhalten, verlinkten Installationsordner abweisen, Super+X/Fensterbetrieb/Beenden ohne fremde Startprogramme. Der Fenstertest verwendete Xterm als sichtbaren Ersatz und bestaetigte den Aufruf des Alacritty-Befehls. Echtes Alacritty fand hier keine passende OpenGL-Konfiguration. Alacrittys Grafikstart, startx auf Void und deine Hardware werden gemeinsam auf deinem Rechner getestet; sie sind noch nicht bestaetigt. Quickshell, Ton und Kontrollzentrum sind noch nicht portiert.
