# Titus-Fenster in Nord

Audio: 360 Pixel breit, Lautstaerke und Stumm, Ausgabegeraete/Standardauswahl, Mikrofon, Medien und Zurueck/Play-Pause/Weiter. NET: 620x680, Aktiv/Trennen, WLAN/Suchen/Verbinden und Passwort, gespeicherte Verbindungen sowie Verbindungseditor. Escape oder ausserhalb klicken schliesst. Deutsche Texte und Nord-Farben; keine Aenderung anderer Anwendungen.

Vorhandenes pactl mit laufendem PulseAudio/PipeWire-Pulse liefert Ton und Geraete; playerctl liefert Medien. nmcli mit laufendem NetworkManager liefert Netzlisten. Fehlende Dienste werden angezeigt, nicht installiert oder aktiviert. WLAN-Passwoerter gehen nur ueber stdin an nmcli, nicht in Befehlsargumente.

Hintergrund: ~/Pictures/backgrounds/nord2560.png auf HDMI-A-0, ~/Pictures/backgrounds/arch-dwm-avatar.png auf DisplayPort-2. wallpaper.sh gleicht Xinerama-Reihenfolge mit den benannten Ausgaengen ab, auch rechts-vor-links. Beide Bilder und feh/xdpyinfo muessen vorhanden sein; keine .fehbg und keine fremden Einstellungen werden gespeichert.

Getestet: Quickshell 0.3.2 unter Xvfb, Fenster/Klick-ausserhalb/Escape, Standardausgabe-Auswahl samt Ruecklesen, gespeichertes Netz und Editor mit Ersatzwerkzeugen, hermetische Audio/Netz/Passwort-und-Monitorzuordnung. Echte Void-Dienste, WLAN-Passwortdialog und beide physischen Monitore sind durch Georg zu pruefen.

Update im bisherigen Ordner: git pull; sh void/start.sh --install; Arbeiten speichern; Super+Shift+Q; erneut anmelden. main bleibt unangetastet.
