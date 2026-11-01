#!/bin/sh
# Local, read-only facts; no machine identifiers or network transmission.
set -u
export LC_ALL=C
row() { printf '%s\t%s\n' "$1" "$(printf '%s' "$2" | tr '\n\t' '  ')"; }
os=$(sed -n 's/^PRETTY_NAME=//p; s/^NAME=//p' /etc/os-release 2>/dev/null | head -1 | tr -d '"')
row OS "${os:-Nicht verfügbar}"
row Kernel "$(uname -sr)"
row Architektur "$(uname -m)"
row Rechner "$(hostname)"
model=$(cat /sys/class/dmi/id/product_name 2>/dev/null || :)
row Modell "${model:-Nicht verfügbar}"
row CPU "$(awk -F: '/model name/ {sub(/^ +/,"",$2); print $2; exit}' /proc/cpuinfo 2>/dev/null)"
row 'CPU-Kerne (logisch)' "$(getconf _NPROCESSORS_ONLN 2>/dev/null)"
awk '/MemTotal:/ {total=$2} /MemAvailable:/ {available=$2} /SwapTotal:/ {swap=$2} /SwapFree:/ {free=$2} END {printf "RAM\t%.1f GiB gesamt · %.1f GiB verfügbar\nSwap\t%.1f GiB gesamt · %.1f GiB frei\n",total/1048576,available/1048576,swap/1048576,free/1048576}' /proc/meminfo 2>/dev/null
row Laufzeit "$(uptime -p 2>/dev/null || uptime 2>/dev/null)"
df -hP -x tmpfs -x devtmpfs 2>/dev/null | awk 'NR>1 {printf "Festplatte %s\t%s gesamt · %s frei · %s belegt\n",$6,$2,$4,$5}'
if command -v xrandr >/dev/null 2>&1; then xrandr --query 2>/dev/null | awk '/ connected/ {printf "Bildschirm %s\t",$1; for(i=3;i<=NF;i++) if($i ~ /^[0-9]+x[0-9]+\+/) printf "%s",$i; print ""}'; fi
row Schrift 'MesloLGS Nerd Font Mono (Void Quickshell)'
row Theme 'Nord (Void Quickshell)'
row Desktop 'dwm-void / X11'
if command -v wpctl >/dev/null 2>&1 && timeout 3 wpctl status >/dev/null 2>&1; then row Audio 'PipeWire verbunden'; elif command -v pactl >/dev/null 2>&1; then row Audio "$(timeout 3 pactl info 2>/dev/null | sed -n 's/^Server Name: //p')"; else row Audio 'Nicht verfügbar'; fi
for tool in arandr setxkbmap xinput nm-connection-editor nmtui bluetoothctl blueman-manager pavucontrol wpctl slock i3lock xdg-settings xdg-mime xbps-install flatpak quickshell nwg-look picom; do
    if command -v "$tool" >/dev/null 2>&1; then row "tool:$tool" 1; else row "tool:$tool" 0; fi
done
row 'Tastaturgruppen' "$(setxkbmap -query 2>/dev/null | awk '/^layout:/ {print $2}')"
row 'Standardbrowser' "$(xdg-settings get default-web-browser 2>/dev/null || :)"
row 'Dateimanager' "$(xdg-mime query default inode/directory 2>/dev/null || :)"
row 'Autostart' "$(ls "$HOME/.config/autostart/"*.desktop 2>/dev/null | wc -l | tr -d ' ') Einträge"
if command -v nmcli >/dev/null 2>&1; then row Netzwerk "$(nmcli -t -f STATE general 2>/dev/null)"; fi
if command -v bluetoothctl >/dev/null 2>&1; then row Bluetooth "$(timeout 3 bluetoothctl list 2>/dev/null)"; fi