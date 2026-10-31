#!/bin/sh
# Use an existing image, never download or change the user's pictures.
set -u
command -v feh >/dev/null 2>&1 || {
    echo 'Hintergrundbild: feh fehlt (Void-Paket feh).' >&2
    exit 0
}
folder=$HOME/Pictures/backgrounds
# feh follows Xinerama's monitor order, not the left-to-right position.
# Resolve output names against each reported geometry before applying both images.
hdmi=$folder/nord2560.png
dp=$folder/arch-dwm-avatar.png
if [ -r "$hdmi" ] && [ -r "$dp" ] && command -v xrandr >/dev/null 2>&1 && command -v xdpyinfo >/dev/null 2>&1; then
    outputs=$(xrandr --query 2>/dev/null)
    heads=$(xdpyinfo -ext XINERAMA 2>/dev/null | awk '/head #[0-9]+:/ {print $3 "@" $5}')
    set --
    valid=1
    for head in $heads; do
        geometry=${head%@*}
        position=${head#*@}
        xy=$(printf '%s' "$position" | tr ',' '+')
        name=$(printf '%s\n' "$outputs" | awk -v geometry="$geometry+$xy" '$2 == "connected" {for(i=3;i<=NF;i++) if ($i == geometry) print $1}')
        case "$name" in
            HDMI-A-0) set -- "$@" "$hdmi" ;;
            DisplayPort-2) set -- "$@" "$dp" ;;
            *) valid=0 ;;
        esac
    done
    if [ "$valid" = 1 ] && [ "$#" -gt 0 ]; then
        feh --no-fehbg --bg-fill "$@" && exit 0
    fi
    echo 'Hintergrundbilder: Monitorzuordnung fehlt; bisheriger Hintergrund bleibt erhalten.' >&2
    exit 0
fi
for image in "$folder"/*; do
    [ -f "$image" ] && [ -r "$image" ] || continue
    case "$image" in
        *.jpg|*.jpeg|*.png|*.webp|*.JPG|*.JPEG|*.PNG|*.WEBP)
            if feh --no-fehbg --bg-fill "$image"; then exit 0; fi
            ;;
    esac
done
echo 'Hintergrundbild: kein lesbares Bild in ~/Pictures/backgrounds gefunden.' >&2
exit 0