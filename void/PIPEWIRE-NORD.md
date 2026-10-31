# Direkte PipeWire-Anzeige

Die Void-Leiste nutzt nun die native PipeWire-Anbindung von Quickshell 0.3.2: Standardausgabe und Mikrofon werden verfolgt, Lautstaerke/Stumm direkt gelesen und gesetzt und Ausgabegeraete direkt gewaehlt. Die bisherige pactl-Abfrage bleibt ein Ersatz, wenn keine native Standardausgabe bereit ist. Es werden keine Dienste gestartet, Pakete installiert oder fremde Einstellungen geaendert.

Die Hinweise fuer Ton und NET sind eigene Nord-Fenster unterhalb der Leiste, damit das Qt-Standardthema weder gelbe Farben noch eine Klickblockade ueber dem Modul erzeugt.

Getestet: echte Quickshell 0.3.2 + getrennte PipeWire 1.6.9-Sitzung mit Null-Ausgabe unter Xvfb, ohne pactl-Antwort: 100 Prozent und Geraet sichtbar; Stumm angeklickt und nativ zurueckgelesen. Nord-Hinweis und Fenster per Bild geprueft. Vorherige Ton/NET-Klicktests mit Ersatzwerkzeugen bestehen ebenfalls. Georgs echte Void-Tongeraete und laufender WirePlumber bleiben auf seinem Rechner zu pruefen.

Georgs pipewire-Ausgabe vom 31.10.2026 zeigt RTKit-Warnungen, keinen Nachweis fuer die Ursache der leeren Anzeige. PipeWire nicht mehrfach starten; falls weiterhin kein Ausgang sichtbar ist, wpctl status und quickshell.log pruefen.
