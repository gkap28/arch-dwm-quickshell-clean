#!/bin/sh
# Use an existing image, never download or change the user's pictures.
set -u
command -v feh >/dev/null 2>&1 || {
    echo 'Hintergrundbild: feh fehlt (Void-Paket feh).' >&2
    exit 0
}
folder=$HOME/Pictures/backgrounds
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
