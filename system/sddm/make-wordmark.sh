#!/usr/bin/env bash
# Copies CachyOS's own wordmark into the theme: themes/cachyos/wordmark.png.
#
# Source: /usr/share/plymouth/themes/cachyos/watermark.png — the wordmark that
# the distro's Plymouth boot splash shows at boot (package
# cachyos-plymouth-theme). 243x66 of artwork, and there is no vector version:
# the CachyOS repos only ship the square emblem (cachyos.svg), and their website
# writes "CachyOS" as text next to that emblem.
#
# It is copied at 1:1, with no resize at all: the artwork is a small bitmap, so
# any enlargement shows its pixel blocks. The theme draws it at exactly this
# size (243x66, smooth: false), which is also how the boot splash shows it.
# Keep these numbers in sync with the Image element in Main.qml.
#
# The mark is also baked into noctalia's lock screen background, so the login
# screen, the lock screen and the boot splash all show the same artwork.
set -euo pipefail

cd "$(dirname "$0")"

src="${1:-/usr/share/plymouth/themes/cachyos/watermark.png}"
[ -f "$src" ] || { echo "wordmark source not found: $src (install cachyos-plymouth-theme)" >&2; exit 1; }

magick "$src" -trim +repage -depth 8 -strip PNG32:themes/cachyos/wordmark.png
identify -format 'themes/cachyos/wordmark.png: %wx%h (native, not scaled)\n' themes/cachyos/wordmark.png

# Noctalia's lock screen background: the flat theme background with the mark
# centred, which is how the greeter lays it out too (mark centred, box below).
# The colour is Akane's background; keep it equal to bgColor in
# themes/cachyos/Main.qml so the greeter and the lock screen match.
# The login box itself is a Noctalia widget placed at cy 520 of 960 logical.
lock_bg="../../noctalia/.config/noctalia/assets/lock-background.png"
if [ -d "$(dirname "$lock_bg")" ]; then
  magick -size 1920x1200 xc:"#12101c" themes/cachyos/wordmark.png -gravity center -composite \
    -depth 8 -strip PNG24:"$lock_bg"
  identify -format "$lock_bg: %wx%h (mark baked in)\n" "$lock_bg"
fi
