#!/bin/bash
# Generate web-optimized thumbnails from pics/ into pics/thumbs/
# Uses macOS sips + cwebp — outputs WebP

set -e

SRC="pics"
DEST="pics/thumbs"
MAX=400
QUALITY=80

mkdir -p "$DEST"

for file in "$SRC"/*; do
  [ -f "$file" ] || continue
  basename=$(basename "$file")
  [[ "$basename" == .DS_Store ]] && continue

  # Output filename: normalize extension to .webp
  outname="${basename%.*}.webp"

  w=$(sips -g pixelWidth "$file" | tail -1 | awk '{print $2}')
  h=$(sips -g pixelHeight "$file" | tail -1 | awk '{print $2}')

  if [ "$w" -gt "$MAX" ] || [ "$h" -gt "$MAX" ]; then
    # Resize via sips to temp, then convert to WebP
    tmpfile=$(mktemp /tmp/thumb_XXXX.jpg)
    sips --resampleHeightWidthMax "$MAX" -s format jpeg -s formatOptions 90 "$file" --out "$tmpfile" 2>/dev/null
    cwebp -q "$QUALITY" "$tmpfile" -o "$DEST/$outname" 2>/dev/null
    rm -f "$tmpfile"
    echo "Resized: $basename → $outname (${w}x${h} → max ${MAX})"
  else
    cwebp -q "$QUALITY" "$file" -o "$DEST/$outname" 2>/dev/null
    echo "Copied:  $basename → $outname (${w}x${h}, already fits)"
  fi
done

echo ""
echo "Done. $(ls "$DEST" | wc -l | tr -d ' ') thumbnails in $DEST/"
du -sh "$DEST"
