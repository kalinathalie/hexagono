#!/bin/bash
# Downloads the InfiniteWorlds (GPL-3.0, github.com/tiny-goat/InfiniteWorlds, branch alpha-v)
# graphics used by the Phoenix-style select screens into this theme.
set -e
cd "$(dirname "$0")/.."
R="https://raw.githubusercontent.com/tiny-goat/InfiniteWorlds/alpha-v/Graphics"

fetch() { # fetch <remote path under Graphics/> <local path under Graphics/>
  local url="$R/$(printf '%s' "$1" | sed 's/ /%20/g')"
  mkdir -p "Graphics/$(dirname "$2")"
  curl -sfL -o "Graphics/$2" "$url" || { echo "FAILED $1"; exit 1; }
  echo "ok  Graphics/$2"
}

# Corner arrows (masked, animated glow) replace the theme's static ones.
rm -f Graphics/CornerArrows/Shift*.png Graphics/CornerArrows/GlowShift*.png
for f in "a_mask (doubleres).png" "dessat_red (doubleres).png" "glow_back (stretch) (doubleres).png" \
         "pattern (stretch) (doubleres).png" "shiftarrow_blue (doubleres).png" "shiftarrow_red (doubleres).png" \
         "red.lua" "blue.lua"; do
  fetch "CornerArrows/$f" "CornerArrows/$f"
done

# Music wheel item frame (328x240 with a label notch) and the center pointer.
fetch "MusicWheel/tg_wheelitem_music.png" "MusicWheel/tg_wheelitem_music.png"
fetch "MusicWheel/tg_pointerwheel_music.png" "MusicWheel/tg_pointerwheel_music.png"

# Large difficulty ball.
fetch "DifficultyDisplay/LargeBall.png" "DifficultyDisplay/LargeBall.png"
echo "done"
