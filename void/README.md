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

Oben eine schmale Leiste auf jedem Monitor: links alle neun Arbeitsflaechen, mittig Datum, Uhrzeit und gegebenenfalls WLAN/Akku, alle 30 Sekunden frisch. Leere Arbeitsflaechen bleiben sichtbar. Noch ohne Kontrollzentrum. Super+X oder Super+Return: Alacritty. Super+J/K: Fenster wechseln; Super+1 bis 9: Arbeitsflaechen wechseln; Super+Shift+C: Fenster schliessen; Super+Shift+Q: zur Konsole zurueck.

Ein vorhandenes Bild aus ~/Pictures/backgrounds wird mit feh auf beiden Monitoren gesetzt. Benoetigt das selbst installierte Void-Paket feh. Es wird kein Bild heruntergeladen und keine ~/.fehbg geschrieben. Fehlendes feh oder fehlende Bilder verhindern den Desktop-Start nicht. Unterschiedliche Bilder je Monitor folgen erst beim spaeteren Kontrollzentrum.

Arbeitsflaechen wechseln per Linksklick auf jedem Monitor unabhaengig. Rechts oeffnet ein gezeichnetes Power-Symbol das benutzereigene Ausschaltmenue: Neustart, Abmelden, Sperren, Ruhezustand, Ausschalten. Wie im Vorbild verlangen alle Aktionen ausser Sperren eine Bestaetigung. Escape oder Klick ausserhalb schliesst das Menue. Dies ist vorerst ein kleines X11-Menue, nicht das komplette Quickshell-Kontrollzentrum. Sperren braucht slock oder i3lock; Ruhezustand braucht elogind/loginctl. Neustart/Ausschalten nutzen loginctl, andernfalls fragt Alacritty ueber sudo nach deinem Passwort fuer den Systembefehl shutdown. Keine Systemdienste oder Berechtigungsregeln werden veraendert.

Die Leiste verwendet eigene Nord-Farben: Hintergrund #2E3440, aktive Arbeitsflaeche #434C5E. Das gilt auch bei abweichenden alten themes.toml-Dateien; Fensterfarben und gespeicherte Einstellungen werden nicht veraendert. Das Power-Symbol braucht keine besondere Symbolschrift.

## Erste Quickshell-Leiste fuer Void

Die Arbeitsflaechen verwenden Titus-Rahmen: 22x22, Rundung 6, 1 Pixel Nord-Rahmen bei Auswahl oder Mauszeiger, Abstand 1. Im Kontrollzentrum oeffnet „Programme“ den an Titus angeglichenen Programmstarter (820x600, auf kleine Bildschirme begrenzt), mit Kategorien, Suche und zweizeiligen 58-Pixel-Eintraegen. Power-Menue: Titus-Aufteilung mit 276-Pixel-Breite und 10-Pixel-Innenabstand. Beide verwenden Hintergrund #2E3440, Auswahl #434C5E und zarte Rahmen #81A1C1 mit 1 Pixel. Der Starter verwendet installierte Desktop-Eintraege und bleibt getrennt von ~/.config. Die Fensterfarben anderer Anwendungen bleiben unveraendert.
Wenn Picom installiert ist, startet es mit der Void-Sitzung und verwendet seine vorhandenen Einstellungen. Meldungen: ~/.local/share/dwm-void/picom.log. Ein bereits laufender anderer Compositor wird nicht beendet; die Sitzung beendet nur ihren eigenen Picom-Prozess. Keine Paketinstallation und keine neue ~/.config-Datei.

Wenn quickshell installiert ist, startet die eigene session.sh eine getrennte Leiste aus ~/.local/share/dwm-void/quickshell/shell.qml. Deine andere Quickshell-Konfiguration und ~/.config bleiben unberuehrt. Links dein Logo mit dem ersten Kontrollmenue, Arbeitsflaechen 1-9 je Monitor, mittig der gemeinsame Status, rechts das Power-Symbol. Das Ausschaltmenue liegt jetzt direkt in Quickshell: Neustart, Abmelden, Sperren, Ruhezustand und Ausschalten. Alle Aktionen ausser Sperren verlangen eine Bestaetigung. Das native Menue bleibt als Rueckfall erhalten. Dein Logo ist 22 Pixel gross, das Power-Symbol 15 Pixel, die anderen Modul-Symbole 13 Pixel und der Leistentext 14 Pixel. Das vollstaendige Quickshell-Kontrollzentrum folgt schrittweise.

Power- und Update-Fenster bleiben klein und undurchsichtig: Hintergrund #2E3440, Auswahl #434C5E, Rahmen #81A1C1 mit genau 1 Pixel. Es gibt keine bildschirmgrosse transparente Flaeche, die ohne Compositor schwarz erscheint. Escape schliesst das Fenster. Der Programmstarter bleibt auch unter dem privaten Void-dwm ein freies 820x600-Fenster; er wird nicht als Leiste erkannt oder bildschirmfuellend angeordnet. Sein einziger Rahmen wird von Quickshell gezeichnet, auch nach Themen-Neuladen. Andere Fenster und vorhandene TOML-Einstellungen bleiben unveraendert.

bar-bridge liest den bestehenden X11-Monitorstatus und sendet eng begrenzte Arbeitsflaechenwuensche mit Monitorposition. Kein Nachahmen von Tastendruecken, kein sudo. Fehlt Quickshell oder beendet es sich, bleibt die native Nord-Leiste als Rueckfall. Die Sitzung beendet nur die von ihr gestartete Quickshell-Instanz. Startmeldungen stehen unter ~/.local/share/dwm-void/quickshell.log.

Nach git pull: sh void/start.sh --install; danach Arbeiten speichern und den Desktop neu starten. Die Quickshell-Variante wurde wirklich unter Xvfb gestartet: Arbeitsflaechen per QML angeklickt, Bruecke fuer beide nachgebildeten dwm-Monitore geprueft, Logo-/Power-Menue geoeffnet und Rueckfall nach Quickshell-Ende geprueft. Qt meldet in dieser Xvfb-Umgebung nur einen Ausgang; zwei echte Quickshell-Ausgaenge und Void-Hardware bleiben fuer Georgs Rechner zu bestaetigen.

## Ton und NET beim Anklicken

Die vorherigen kleinen Statusfenster sind durch die Titus-Aufteilung in Nord ersetzt: Audio (360 Pixel breit) mit Lautstaerke, Stumm, Ausgabegeraeten, Mikrofon und Mediensteuerung; Netzwerk (620x680) mit Aktiv, WLAN, gespeicherten Verbindungen und Verbindungseditor. Escape und ein Klick ausserhalb schliessen die Fenster. Auf kleineren Bildschirmen bleibt der Inhalt scrollbar. Die Texte sind auf Deutsch; die Farben anderer Programme bleiben unveraendert.

Vorhandenes `pactl` mit laufendem PulseAudio/PipeWire-Pulse liefert Ton und Geraete, `playerctl` liefert Medien. `nmcli` mit laufendem NetworkManager liefert Netzlisten und Verbindungsaktionen. Fehlende Dienste werden angezeigt, nicht installiert oder eingeschaltet; eine bestehende andere Netzwerkverwaltung bleibt unangetastet. WLAN-Passwoerter gehen nur ueber die Standardeingabe an nmcli, nicht in Befehlsargumente oder Meldungsdateien. Echte Dienste und beide physischen Void-Monitore muss Georg pruefen; die QML-Fenster werden separat mit Quickshell 0.3.2 unter Xvfb geprueft.

## Zusaetzliche Programmtasten

## Updates neben der Uhr

Das originale Titus-Kreis-Updatesymbol (13 Pixel, ohne Symbolschrift; Bild aus config/quickshell/assets/update-center/dwm-update-center.png, auf 64 Pixel verkleinert in update-symbol.svg eingebettet) zeigt die gemeinsame Zahl fuer XBPS und Flatpak. Ein Klick oeffnet Nord-Knoepfe „XBPS updaten“ und „Flatpak updaten“ mit getrennten Zahlen. XBPS prueft nur die bereits gespeicherten Paketlisten; neue Listen werden erst beim bewussten Update geladen. Flatpak zaehlt Benutzer- und Systeminstallation. „~“ vor der Zahl bedeutet unvollstaendige Pruefung, „—“ nicht verfuegbar. Die Pruefung laeuft alle fuenf Minuten mit Zeitgrenzen und installiert nichts.

XBPS startet Alacritty mit sudo fuer /usr/bin/xbps-install -Su; nur dieser Systembefehl wird erhoeht, kein Benutzer-Helfer. Flatpak startet im Terminal nacheinander update --user und update --system. Beide zeigen ihre eigenen Rueckfragen; keine automatische Bestaetigung. Das Terminal bleibt fuer das Ergebnis offen. Echte Paketupdates und Alacritty auf Void sind noch von Georg zu pruefen; QML-Klicks verwenden harmlose Ersatzaktionen.

Nach `git pull` im Projektordner: `sh void/update-hotkeys.sh`.
Super+Q schliesst das aktive Fenster, Super+Shift+Return startet Thunar,
Super+B startet Brave (brave, brave-browser oder brave-browser-stable),
Super+Return startet Alacritty. Super+X und Super+Shift+Q bleiben erhalten.
Thunar und Brave muessen bereits installiert sein. Die erste vorherige
Tastendatei wird als hotkeys.toml.before-app-keys im gleichen isolierten Ordner gesichert.
Die Tasten werden beim Speichern automatisch neu geladen; kein Desktop-Neustart noetig.

## Monitoranordnung nach Neustart

HDMI-A-0: 2560x1080 links bei 0x0. DisplayPort-2: 1920x1080 rechts bei 2560x0.
Nach `git pull` einmal `sh void/start.sh --install` ausfuehren.
Die Anordnung wird vor jedem Desktop-Start ueber das benutzereigene monitors.sh wiederhergestellt.
Die vorhandenen Bilder ~/Pictures/backgrounds/nord2560.png und ~/Pictures/backgrounds/arch-dwm-avatar.png werden HDMI-A-0 beziehungsweise DisplayPort-2 zugeordnet. wallpaper.sh gleicht die Xinerama-Reihenfolge mit den benannten Ausgaengen ab; die Reihenfolge darf auch rechts-vor-links sein. feh speichert dabei keine andere Desktop-Konfiguration. Beide Dateien muessen lesbar vorhanden sein.
Sind nicht beide Monitore angeschlossen oder scheitert xrandr, bleibt der Desktop-Start moeglich.
Keine Aenderung an ~/.xinitrc, ~/.zprofile oder Systemdateien.

## Sicherheit

Nur ~/.local/share/dwm-void wird beschrieben: dwm, xinitrc, status.sh, monitors.sh, wallpaper.sh und config mit hotkeys.toml, themes.toml und window-rules.toml. Vorhandene TOML-Dateien bleiben erhalten; der temporaere Bauordner wird entfernt. ~/.config, ~/.xinitrc, /usr, Dienste und Pakete werden nicht angefasst. Xorg/startx kann seine eigenen normalen Sitzungsdateien anlegen. In einer privaten Baukopie werden die Original-Start-/Stop-Routinen und der automatische Themen-Helfer abgeschaltet und die TOML-Pfade umgeleitet. Der originale Quelltext bleibt unveraendert.

## Pruefstand

Sicherheits-, Hintergrund- und Startertests erfolgreich. Zwei Xinerama-Monitore mit Georgs Groessen wurden unter Xvfb nachgebildet: Arbeitsflaechen 1-9 wechseln unabhaengig auf jedem Monitor; ein Fenster auf dem anderen Monitor bleibt sichtbar. Beide Leisten aktualisieren den Status auch ohne Fokuswechsel; Bilder bestaetigen alle neun Arbeitsflaechen und mittigen Status. Xterm ersetzte Alacritty im Fenstertest. Diese nachgebildeten Tests ersetzen keine Hardwarepruefung. Georg bestaetigte Desktop, Leiste und Monitoranordnung nach Neustart auf Void; die neuen Leisten und der Hintergrund sind dort noch zu bestaetigen. Quickshell, Ton und Kontrollzentrum sind noch nicht portiert.

## Ton

Void startet PipeWire nicht von selbst. Ist pipewire installiert und laeuft fuer dich noch nicht, startet die Sitzung pipewire, dazu wireplumber (wenn PipeWire es nicht schon selbst startet) und pipewire-pulse (falls installiert). Beim Abmelden endet nur dieser eigene Ton. Ein schon laufendes PipeWire bleibt unberuehrt. Meldungen: ~/.local/share/dwm-void/pipewire.log. Keine Systemdateien, keine Dienste, nichts in ~/.config. RTKit-Warnungen sind harmlos.

## Schrift, Uhr und Tastatur

Quickshell verwendet wie Titus MesloLGS Nerd Font Mono (normal und fett). Die beiden Originaldateien von Nerd Fonts v3.4.0 werden beim Einrichten mit SHA-256-Pruefung nur nach ~/.local/share/dwm-void/quickshell/fonts geladen; curl wird benoetigt. Keine Pakete und keine globale Schrifteinstellung werden veraendert. Bei fehlendem Netz bleibt eine Ersatzschrift und die Meldung; spaeter erneut sh void/start.sh --install ausfuehren.

Uhr/Datum erscheinen fett als So 01 Nov- 13.40; die Uhr verwendet die lokale Rechnerzeit und deutsche Wochentage unabhaengig von der Spracheinstellung. Der anklickbare Tastaturtext rechts wechselt US → DE → GR → US; beide Leisten lesen denselben echten X11-Zustand. setxkbmap muss vorhanden sein (Void-Paket setxkbmap). Beim Anmelden startet diese Sitzung mit US, ohne Systemdateien oder bestehende XKB-Optionen zu veraendern.
