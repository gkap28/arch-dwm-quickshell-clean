#!/bin/sh
# Ausgabe pro Zeile: "Super + Shift + q|Beschreibung" aus der installierten hotkeys.toml
f="$HOME/.local/share/dwm-void/config/hotkeys.toml"
[ -r "$f" ] || exit 1
awk '
function field(line, name,   t) {
  t = line
  if (index(t, name "=") == 0) return ""
  sub(".*" name "=", "", t); sub(/[ ,}].*/, "", t)
  return t
}
/^ *\{ *mod=/ {
  line = $0
  mod = line;  sub(/.*mod="/, "", mod);  sub(/".*/, "", mod)
  key = line;  sub(/.*key="/, "", key);  sub(/".*/, "", key)
  fn = line;   sub(/.*func="/, "", fn);  sub(/".*/, "", fn)
  if (fn == "focusstack") desc = (field(line, "i") + 0 > 0) ? "Nächstes Fenster fokussieren" : "Vorheriges Fenster fokussieren"
  else if (fn == "setmfact") desc = (field(line, "f") + 0 > 0) ? "Hauptbereich vergrößern" : "Hauptbereich verkleinern"
  else if (fn == "setlayout") desc = "Layout: Kacheln"
  else if (fn == "togglefloating") desc = "Fenster schwebend umschalten"
  else if (fn == "fullscreen") desc = "Vollbild umschalten"
  else if (fn == "killclient") desc = "Fenster schließen"
  else if (fn == "quit") desc = "dwm beenden"
  else if (fn == "view" || fn == "tag") {
    v = field(line, "ui") + 0; n = 1
    while (v > 1) { v = v / 2; n++ }
    desc = (fn == "view") ? "Tag " n " anzeigen" : "Fenster an Tag " n " senden"
  }
  else if (fn == "spawn") {
    if (index(line, "cmd=") > 0) desc = "Browser öffnen"
    else {
      cmd = line; sub(/.*exec=\[/, "", cmd); sub(/\].*/, "", cmd)
      gsub(/"/, "", cmd); gsub(/\$terminal/, "alacritty", cmd)
      desc = "Starten: " cmd
    }
  }
  else desc = fn
  gsub(/SUPER/, "Super", mod); gsub(/SHIFT/, "Shift", mod); gsub(/CTRL/, "Ctrl", mod); gsub(/ /, " + ", mod)
  print mod " + " key "|" desc
}' "$f"
