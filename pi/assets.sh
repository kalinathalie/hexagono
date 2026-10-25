#!/bin/bash
# Downloads and builds the theme's essential art into its git-ignored folders. The art
# belongs to Andamiro and to the authors of phyrebird and XSanity, so the repository
# keeps the recipe instead of the files:
#   Graphics/Phoenix   from phyrebird (github.com/rayden-61/phyrebird): channel cards,
#                      command window, difficulty balls, READY, grades; then the extra
#                      cards and the sharp labels made by tools/, the Phoenix 2 logo and
#                      the title video and the stage break animation (YouTube), cut and
#                      converted (pi/assets/title.py, pi/assets/stagebreak.py)
#   Graphics/XSanity, Graphics/XSCommandWindow and XSanity's Pump noteskins, from
#                      XSanity 0.96.0 on xsanity.net (or an install or zip you already
#                      have: --xsanity PATH); 0.97 changed the art
#                      The XSanity download has 11 noteskins; --noteskins PATH installs a
#                      bigger set kept separately (a zip or folder with a "pump" folder)
#   Graphics/Phoenix/Avatars  the Phoenix player icons from piugame.com, offered by
#                      profile select (pi/assets/avatars.py)
#   Thumbs             the wheel thumbnails, when songs are already installed
# Parts already in place are skipped: delete a folder to build it again.
#
# Usage: bash pi/assets.sh [--xsanity PATH] [--noteskins PATH] [--no-xsanity] [--no-video] [--font TTF]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="$(cd "$HERE/.." && pwd)"
PX="$THEME/Graphics/Phoenix"
NOTESKINS="${NOTESKINS:-$HOME/.project-outfox/NoteSkins}"
SONGS="$HOME/.project-outfox/Songs"
WORK="${XDG_CACHE_HOME:-$HOME/.cache}/hexagono-assets"
VENV="$WORK/venv"
# the Windows zip: the art and noteskins are the same on every system, and it is the
# only 0.96.0 package still online
XSANITY_URL="https://download.xsanity.net/XSanity%200.96.0.zip"
XSANITY_DIR=""; XSANITY=1; VIDEO=1; FONT=""; SKINS=""
while [ $# -gt 0 ]; do
    case "$1" in
        --xsanity) XSANITY_DIR="$2"; shift ;;
        --noteskins) SKINS="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift ;;
        --no-xsanity) XSANITY=0 ;;
        --no-video) VIDEO=0 ;;
        --font) FONT="$2"; shift ;;
        *) echo "unknown option $1" >&2; exit 1 ;;
    esac
    shift
done

say() { printf '\n-- %s\n' "$*"; }
WARNINGS=()
warn() { WARNINGS+=("$*"); echo "warning: $*" >&2; }

mkdir -p "$WORK"
if [ ! -x "$VENV/bin/python" ]; then
    python3 -m venv --system-site-packages "$VENV"
fi
# yt-dlp changes often to keep up with YouTube, so it comes from pip, always the newest
"$VENV/bin/pip" install -q -U "yt-dlp[default]" psd-tools
PY="$VENV/bin/python"

say "Phoenix art from phyrebird"
if [ -f "$PX/Channels/BLANK_RED.png" ] && [ -f "$PX/CommandWindow/icons 11x11.png" ] && [ -d "$PX/RecordGrades" ]; then
    echo "already there"
else
    "$PY" "$HERE/assets/phyrebird.py" "$THEME"
fi

say "Generated cards and labels"
if [ -z "$FONT" ]; then
    # the extra cards use Verdana Bold Italic, the closest font to Phoenix's
    for f in /usr/share/fonts/truetype/msttcorefonts/verdanaz.ttf /usr/share/fonts/truetype/msttcorefonts/Verdana_Bold_Italic.ttf; do
        [ -f "$f" ] && FONT="$f" && break
    done
fi
if [ -z "$FONT" ]; then
    FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf
    warn "Verdana Bold Italic not found, the extra cards use DejaVu Sans; for the original look install ttf-mscorefonts-installer (it asks you to accept Microsoft's license) and run this again after deleting Graphics/Phoenix/Channels/CAT_GENRE.png"
fi
if [ -f "$PX/Channels/CAT_GENRE.png" ] && [ -f "$PX/Channels/C_HDLV_28.png" ] && [ -f "$PX/Channels/C_LV_26.png" ]; then
    echo "cards already there"
else
    "$PY" "$THEME/tools/make_phoenix_cards.py" --channels "$PX/Channels" --font "$FONT"
fi
[ -f "$PX/CommandWindow/labels 1x10.png" ] || "$PY" "$THEME/tools/make_phoenix_labels.py"

say "Phoenix 2 logo"
[ -f "$PX/Logo/PhoenixLogo.png" ] && echo "already there" || "$PY" "$THEME/tools/make_phoenix_logo.py" \
    || warn "the logo could not be downloaded (tools/make_phoenix_logo.py --src takes another image)"

say "Title video"
if [ "$VIDEO" = 0 ]; then
    echo "skipped (--no-video): the title screen shows the logo"
elif [ -f "$PX/Title/info.ini" ]; then
    echo "already there"
else
    "$PY" "$HERE/assets/title.py" "$PX/Title" --work "$WORK/title" --yt-dlp "$VENV/bin/yt-dlp" \
        || { rm -f "$PX/Title/info.ini"; warn "the title video could not be built; the title screen shows the logo"; }
fi

say "Stage break animation"
if [ "$VIDEO" = 0 ]; then
    echo "skipped (--no-video): a broken stage shows the theme's own animation"
elif [ -f "$PX/StageBreak/info.ini" ]; then
    echo "already there"
else
    "$PY" "$HERE/assets/stagebreak.py" "$PX/StageBreak" --work "$WORK/stagebreak" --yt-dlp "$VENV/bin/yt-dlp" \
        || { rm -f "$PX/StageBreak/info.ini"; warn "the stage break animation could not be built; a broken stage shows the theme's own animation"; }
fi

say "XSanity art and noteskins"
if [ "$XSANITY" = 0 ]; then
    echo "skipped (--no-xsanity)"
elif [ -d "$THEME/Graphics/XSanity/ChanGraph" ] && [ -d "$NOTESKINS/pump/xs_default" ] && [ -z "$SKINS" ]; then
    echo "already there"
else
    src="$XSANITY_DIR"
    if [ -z "$src" ]; then
        echo "downloading XSanity 0.96.0 (about 600 MB)"
        curl -L --fail -o "$WORK/xsanity.zip" "$XSANITY_URL" && src="$WORK/xsanity.zip"
    fi
    if [ -n "$src" ]; then
        "$PY" "$HERE/assets/xsanity.py" "$src" "$THEME" "$NOTESKINS" ${SKINS:+--noteskins "$SKINS"} \
            || warn "copying the XSanity art failed"
    else
        warn "XSanity could not be downloaded; run again with --xsanity PATH (an XSanity 0.96.0 install or zip)"
    fi
    rm -f "$WORK/xsanity.zip"
fi

say "Player icons"
"$PY" "$HERE/assets/avatars.py" "$PX/Avatars" \
    || warn "some player icons could not be downloaded; run this again to fetch the rest"

say "Wheel thumbnails"
if ls -d "$SONGS"/*/ >/dev/null 2>&1; then
    (cd "$THEME" && nice -n 10 "$PY" tools/make_thumbs.py)
else
    echo "no songs yet: after copying them, run  cd $THEME && python3 tools/make_thumbs.py"
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
    say "Finished with warnings"
    printf '  - %s\n' "${WARNINGS[@]}"
else
    say "Theme art ready"
fi
