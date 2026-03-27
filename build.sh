#!/bin/bash
# Generate web-optimized thumbnails from pics/ into pics/thumbs/
# Uses macOS sips — no dependencies needed

set -e

SRC="pics"
DEST="pics/thumbs"
MAX=1200

mkdir -p "$DEST"

for file in "$SRC"/*; do
  [ -f "$file" ] || continue
  basename=$(basename "$file")
  [[ "$basename" == .DS_Store ]] && continue

  # Output filename: normalize extension to .jpg
  outname="${basename%.*}.jpg"

  w=$(sips -g pixelWidth "$file" | tail -1 | awk '{print $2}')
  h=$(sips -g pixelHeight "$file" | tail -1 | awk '{print $2}')

  if [ "$w" -gt "$MAX" ] || [ "$h" -gt "$MAX" ]; then
    sips --resampleHeightWidthMax "$MAX" -s format jpeg -s formatOptions 80 "$file" --out "$DEST/$outname" 2>/dev/null
    echo "Resized: $basename → $outname (${w}x${h} → max ${MAX})"
  else
    sips -s format jpeg -s formatOptions 80 "$file" --out "$DEST/$outname" 2>/dev/null
    echo "Copied:  $basename → $outname (${w}x${h}, already fits)"
  fi
done

echo ""
echo "Done. $(ls "$DEST" | wc -l | tr -d ' ') thumbnails in $DEST/"
