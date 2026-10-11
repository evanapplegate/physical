#!/bin/bash
# Generate web-optimized thumbnails from pics/ into pics/thumbs/
# Uses macOS sips + ffmpeg (libwebp), outputs WebP:
#   pics/thumbs/      longest side 800 (desktop)
#   pics/thumbs/600/  600 wide, only when the 800 thumb is wider than that (mobile srcset)
# Thumbs newer than their source are skipped.

set -e

SRC="pics"
DEST="pics/thumbs"
DEST_M="pics/thumbs/600"
MAX=800
MOBILE_W=600
QUALITY=80

mkdir -p "$DEST" "$DEST_M"
tmpfile=$(mktemp /tmp/thumb_XXXX).jpg
trap 'rm -f "$tmpfile"' EXIT

webp() { ffmpeg -hide_banner -loglevel error -y -i "$1" -c:v libwebp -quality "$QUALITY" "$2"; }

for file in "$SRC"/*; do
  [ -f "$file" ] || continue
  basename=$(basename "$file")
  [[ "$basename" == .DS_Store ]] && continue

  # Output filename: normalize extension to .webp
  outname="${basename%.*}.webp"

  if [ ! "$DEST/$outname" -nt "$file" ]; then
    w=$(sips -g pixelWidth "$file" | tail -1 | awk '{print $2}')
    h=$(sips -g pixelHeight "$file" | tail -1 | awk '{print $2}')

    if [ "$w" -gt "$MAX" ] || [ "$h" -gt "$MAX" ]; then
      # Resize via sips to temp, then convert to WebP
      sips --resampleHeightWidthMax "$MAX" -s format jpeg -s formatOptions 90 "$file" --out "$tmpfile" >/dev/null 2>&1
      webp "$tmpfile" "$DEST/$outname"
      echo "Resized: $basename → $outname (${w}x${h} → max ${MAX})"
    else
      webp "$file" "$DEST/$outname"
      echo "Copied:  $basename → $outname (${w}x${h}, already fits)"
    fi
  fi

  tw=$(ffprobe -v error -show_entries stream=width -of csv=p=0 "$DEST/$outname")
  if [ "$tw" -gt "$MOBILE_W" ] && [ ! "$DEST_M/$outname" -nt "$file" ]; then
    sips --resampleWidth "$MOBILE_W" -s format jpeg -s formatOptions 90 "$file" --out "$tmpfile" >/dev/null 2>&1
    webp "$tmpfile" "$DEST_M/$outname"
    echo "Mobile:  $basename → 600/$outname"
  fi
done

echo ""
echo "Done. $(ls "$DEST"/*.webp | wc -l | tr -d ' ') thumbnails in $DEST/, $(ls "$DEST_M" | wc -l | tr -d ' ') in $DEST_M/"
du -sh "$DEST"
