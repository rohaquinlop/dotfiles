#!/usr/bin/env bash
# Regenerates themes/cachyos/wordmark.png: the login mark, in white.
#
# The old mark was the Plymouth boot watermark: only 243x66, teal and cyan. It
# was too soft for a wallpaper background and its colours fought the Akane
# palette. This one is built instead from two crisp sources:
#
#   1. the distro's vector emblem, /usr/share/icons/cachyos.svg (what GDM uses),
#      rasterised at 200px and recoloured to white through its alpha channel;
#   2. "CACHYOS" set in Noto Sans Mono Condensed Black - the heavy cut of the
#      terminal font - in white.
#
# White keeps it readable over any wallpaper, and the emblem is vector, so the
# mark stays sharp at any screen scale. Set WD_TEXT to change the name.
set -euo pipefail

cd "$(dirname "$0")"

emblem_svg="${EMBLEM_SVG:-/usr/share/icons/cachyos.svg}"
emblem_px=200
text="${WD_TEXT:-CACHYOS}"
font="$(fc-match -f '%{file}' 'NotoSansM Nerd Font Mono:style=Condensed Black')"

[ -f "$emblem_svg" ] || { echo "emblem not found: $emblem_svg (install cachyos-icons?)" >&2; exit 1; }
[ -f "$font" ] || { echo "font not found: install ttf-noto-nerd" >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# emblem: vector -> raster -> white silhouette (the facets are gradients, so the
# monochrome version is the shape itself)
magick -background none -density 400 "$emblem_svg" -resize "${emblem_px}x${emblem_px}" "$work/e.png"
magick "$work/e.png" -alpha extract -alpha off "$work/e-alpha.png"
magick -size "${emblem_px}x${emblem_px}" xc:white "$work/e-alpha.png" -alpha off -compose CopyOpacity -composite "$work/emblem.png"

# name: white text, tracked out a little like the original wordmark
magick -background none -fill white -font "$font" -pointsize 140 -kerning 6 \
  label:"$text" -trim +repage "$work/text.png"

# Trim both parts, then place them by hand: -smush and -gravity misalign with
# this patched font's metrics, and the offsets are easier to reason about.
magick "$work/emblem.png" -trim +repage "$work/emblem.png"
magick "$work/text.png" -trim +repage "$work/text.png"
read -r ew eh <<<"$(magick identify -format '%w %h' "$work/emblem.png")"
read -r tw th <<<"$(magick identify -format '%w %h' "$work/text.png")"
gap=36

magick -size "$((ew + gap + tw))x${eh}" xc:none \
  "$work/emblem.png" -geometry +0+0 -composite \
  "$work/text.png" -geometry "+$((ew + gap))+$(((eh - th) / 2))" -composite \
  -depth 8 -strip PNG32:themes/cachyos/wordmark.png

identify -format 'themes/cachyos/wordmark.png: %wx%h (white, emblem from vector)\n' themes/cachyos/wordmark.png
