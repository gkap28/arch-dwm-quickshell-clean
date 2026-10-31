# Erste getrennte Quickshell-Leiste fuer Void

Nach git pull: sh void/start.sh --install. Arbeiten speichern und Desktop neu starten. Wenn quickshell vorhanden ist, startet die benutzereigene session.sh diese separate Leiste. Kein sudo, keine Aenderung an ~/.config oder Systemdateien.

Nord-Hintergrund #2E3440, aktive Arbeitsflaeche #434C5E; links Georgs Logo, Arbeitsflaechen 1-9, mittig Status, rechts ein gezeichnetes Power-Symbol ohne Symbolschrift. Beide Monitore bekommen eigene Quickshell-Fenster. Die Arbeitsflaechen-Bruecke sendet explizite Monitorpositionen statt Tastendruecke.

Kontroll- und Power-Menue bleiben vorerst die vorhandenen X11-Menues. Das komplette Quickshell-Kontrollzentrum folgt schrittweise. Fehlt Quickshell oder beendet es sich, bleibt die native Nord-Leiste als Rueckfall. Nur diese Sitzung beendet ihre eigene Quickshell-Instanz. Meldungen: ~/.local/share/dwm-void/quickshell.log.

Geprueft: echte Quickshell-Leiste unter Xvfb, QML-Arbeitsflaechen-Klicks, Bruecke auf zwei nachgebildeten dwm-Monitoren, Logo-/Power-Menue und native Rueckfallleiste. Xterm ersetzt Alacritty im Test. Qt meldet unter Xvfb nur einen Ausgang: zwei echte Quickshell-Monitore und Void-Hardware muss Georg bestaetigen. Upstream-Dateien und main unveraendert.
