#!/bin/bash
# Sets up a Raspberry Pi 5 (Raspberry Pi OS 64-bit with the desktop) as a Pump It Up
# machine like the reference one: Project OutFox 0.5.0-pre043, this theme and its
# essential art, 60 Hz on any screen, the game opening at login (and again after a
# crash), the saved preferences, the pad mapping and the profile slots.
# Songs are not part of it: copy them to ~/.project-outfox/Songs (see pi/README.md).
#
# Run it from the theme's own clone, which must be ~/.project-outfox/Themes/Infinitesimal:
#   git clone https://github.com/kalinathalie/hexagono.git ~/.project-outfox/Themes/Infinitesimal
#   bash ~/.project-outfox/Themes/Infinitesimal/pi/setup.sh [--no-assets] [--no-system]
# It can be run again: existing files are kept as *.bak-hexagono before being replaced.
#   --no-assets   skip pi/assets.sh (the theme art)
#   --no-system   skip the steps that need sudo: packages, desktop autologin, screen blanking
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$HERE/config"
DATA="$HOME/.project-outfox"
THEME="$DATA/Themes/Infinitesimal"
OUTFOX_URL="https://github.com/TeamRizu/OutFox/releases/download/OF5.0.0-043/OutFox-alpha-0.5.0-pre-043-Final-RaspberryPi-debian12-arm64-aarch64-current-date-20250927.tar.gz"
SLOTS=6                       # reserved profiles that CREATE PROFILE renames (Modules/Profile.Slots.lua)
SLOT_NAME="~HEXAGONO_SLOT~"
ASSETS=1
SYSTEM=1
for arg in "$@"; do
    case "$arg" in
        --no-assets) ASSETS=0 ;;
        --no-system) SYSTEM=0 ;;
        *) echo "unknown option $arg" >&2; exit 1 ;;
    esac
done

say() { printf '\n== %s\n' "$*"; }

if [ "$(cd "$HERE/.." && pwd)" != "$THEME" ]; then
    echo "Clone the repository to $THEME and run pi/setup.sh from there (see pi/README.md)." >&2
    exit 1
fi
if [ "$(uname -m)" != "aarch64" ]; then
    echo "This is meant for a 64-bit Raspberry Pi OS (aarch64)." >&2
    exit 1
fi

# Replace a file, keeping a different existing one as *.bak-hexagono
install_file() {   # source target [mode]
    mkdir -p "$(dirname "$2")"
    if [ -f "$2" ] && ! cmp -s "$1" "$2"; then cp -p "$2" "$2.bak-hexagono"; fi
    cp "$1" "$2"
    [ -n "${3:-}" ] && chmod "$3" "$2"
    return 0
}
# Same, replacing @HOME@ with the user's home folder
install_template() {   # source target
    local tmp; tmp="$(mktemp)"
    sed "s|@HOME@|$HOME|g" "$1" > "$tmp"
    install_file "$tmp" "$2"
    rm -f "$tmp"
}

if [ "$SYSTEM" = 1 ]; then
    say "Desktop at boot, screen always on"
    # log in to the desktop automatically (the game opens from the desktop's autostart)
    # and never blank the screen while waiting on the title
    sudo raspi-config nonint do_boot_behaviour B4
    sudo raspi-config nonint do_blanking 1
    say "Packages"
    sudo apt-get update
    # ffmpeg, python3-venv and nodejs are for pi/assets.sh (title video); Pillow and numpy
    # for the theme's tools (thumbnails, generated cards); grim takes screenshots;
    # wlr-randr and kanshi set the screen mode
    sudo apt-get install -y git curl xz-utils ffmpeg python3 python3-venv python3-pil python3-numpy nodejs grim wlr-randr kanshi
    say "Card font"
    # Verdana Bold Italic, the font of the generated channel cards; the installer shows
    # Microsoft's license: decline it and the cards use DejaVu Sans instead
    sudo apt-get install -y ttf-mscorefonts-installer || echo "Microsoft fonts not installed: the generated cards use DejaVu Sans"
fi

say "Project OutFox"
if ls -d "$HOME"/ProjectOutFox/OutFox-*/OutFox >/dev/null 2>&1; then
    echo "already installed: $(ls -d "$HOME"/ProjectOutFox/OutFox-*/ | head -1)"
else
    mkdir -p "$HOME/ProjectOutFox"
    curl -L --fail -o "$HOME/ProjectOutFox/outfox.tar.gz" "$OUTFOX_URL"
    tar -xzf "$HOME/ProjectOutFox/outfox.tar.gz" -C "$HOME/ProjectOutFox"
    rm -f "$HOME/ProjectOutFox/outfox.tar.gz"
fi

say "Screen, autostart and pointer"
for f in display-60hz display-watch outfox-run outfox-stop; do
    install_file "$CONF/bin/$f" "$HOME/.local/bin/$f" 755
done
install_template "$CONF/labwc/autostart" "$HOME/.config/labwc/autostart"
install_file "$CONF/labwc/rc.xml" "$HOME/.config/labwc/rc.xml"
install_template "$CONF/kanshi/config" "$HOME/.config/kanshi/config"
# a desktop icon to open the game again after quitting it
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
install_template "$CONF/desktop/OutFox.desktop" "$DESKTOP_DIR/OutFox.desktop"

say "OutFox preferences, theme options and pad mapping"
mkdir -p "$DATA/Save"
# set only the listed keys, where OutFox keeps them, including the per-game theme ([Game-pump])
[ -f "$DATA/Save/Preferences.ini" ] && cp -p "$DATA/Save/Preferences.ini" "$DATA/Save/Preferences.ini.bak-hexagono"
python3 "$HERE/merge_prefs.py" "$CONF/outfox/Preferences.ini" "$DATA/Save/Preferences.ini"
install_file "$CONF/outfox/OutFoxPrefs.ini" "$DATA/Save/OutFoxPrefs.ini"
install_file "$CONF/outfox/Keymaps.ini" "$DATA/Save/Keymaps.ini"

say "Profile slots"
PROFILES="$DATA/Save/LocalProfiles"
mkdir -p "$PROFILES"
have=$(grep -l "^DisplayName=$SLOT_NAME$" "$PROFILES"/*/Editable.ini 2>/dev/null | wc -l || true)
id=0
while [ "$have" -lt "$SLOTS" ]; do
    dir="$PROFILES/$(printf '%08d' "$id")"
    id=$((id + 1))
    [ -e "$dir" ] && continue
    mkdir -p "$dir"
    printf '[Editable]\nBirthYear=0\nCharacterID=default\nDisplayName=%s\nIgnoreStepCountCalories=0\nIsMale=0\nLastUsedHighScoreName=\nVoomax=0.000000\nWeightPounds=0\n' "$SLOT_NAME" > "$dir/Editable.ini"
    printf '[ListPosition]\nPriority=%d\nType=Normal\n\n[Online]\nInputType=0\nRegistered=0\nToken=\n' $((100 + id - 1)) > "$dir/Type.ini"
    sed -e "s|@NAME@|$SLOT_NAME|" -e "s|@GUID@|$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')|" "$CONF/outfox/slot-Stats.xml" > "$dir/Stats.xml"
    have=$((have + 1))
    echo "created $(basename "$dir")"
done
echo "$have profile slots"

if [ "$ASSETS" = 1 ]; then
    say "Theme art"
    bash "$HERE/assets.sh"
fi

say "Done"
cat <<EOF
Next:
  1. Copy the song folders to $DATA/Songs (not part of this kit).
  2. Build the wheel thumbnails:  cd $THEME && python3 tools/make_thumbs.py
  3. Reboot: the game opens at login, in 60 Hz on any screen.
If your pad is not the reference one, map it again in OutFox (Options, key/joystick mappings).
EOF
