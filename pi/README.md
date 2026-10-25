# Raspberry Pi kit

**English** | [Português (Brasil)](README.pt-BR.md)

Everything needed to turn a Raspberry Pi 5 into the reference machine: Project OutFox, this theme with all of its art, the screen and autostart setup, the preferences and the pad mapping. Songs are not part of it.

## Steps

1. Write **Raspberry Pi OS (64-bit) with desktop** to the card (Raspberry Pi Imager), boot it and connect it to the internet.
2. Clone the theme to the folder OutFox reads:

   ```bash
   git clone https://github.com/kalinathalie/hexagono.git ~/.project-outfox/Themes/Infinitesimal
   ```

3. Run the setup (about 20 minutes, most of it downloads and the title video):

   ```bash
   bash ~/.project-outfox/Themes/Infinitesimal/pi/setup.sh
   ```

   Midway, the installer of Microsoft's fonts shows their license. Accepting it gives the generated channel cards their original font (Verdana); declining it is fine too, the cards then use DejaVu Sans.
4. Copy the song folders to `~/.project-outfox/Songs`, one folder per version, named like `17 - PHOENIX 2` (see [Songs](#songs)), then build the wheel thumbnails:

   ```bash
   cd ~/.project-outfox/Themes/Infinitesimal && python3 tools/make_thumbs.py
   ```

5. Optional: the XSanity download has 11 noteskins. To install the full set of the reference Pi (61), copy its `noteskins-xsanity.zip` to the Pi and run:

   ```bash
   bash ~/.project-outfox/Themes/Infinitesimal/pi/assets.sh --noteskins ~/noteskins-xsanity.zip
   ```

6. Reboot. The Pi logs in to the desktop and the game opens on its own, at 60 Hz on whatever screen is connected.

Both scripts can be run again at any time: they skip what is already in place, and keep any file they replace as `*.bak-hexagono`.

## What `setup.sh` does

| Step | Result |
|---|---|
| System (`sudo`) | desktop autologin, no screen blanking; packages: git, curl, ffmpeg, Python with Pillow and numpy, nodejs, grim, wlr-randr, kanshi, Microsoft fonts (optional) |
| Project OutFox | 0.5.0-pre043 for Raspberry Pi, in `~/ProjectOutFox` |
| Screen | `~/.local/bin/display-60hz` picks the best 60 Hz mode up to about 1080p on every screen (TVs often prefer 4K at 30 Hz, which caps the game at 30 FPS); run at login and by kanshi whenever a screen is connected. `~/.local/bin/display-watch` checks the screens every 2 s for what kanshi misses, like a TV that was off at boot being turned on (it jumps to its preferred 4K at 30 Hz): it puts it back at 60 Hz and restarts the game if it was opened on another screen or if the screen went away meanwhile (turning a TV on can drop the HDMI output for a moment) |
| Autostart | `~/.config/labwc/autostart` starts display-watch and opens the game through `~/.local/bin/outfox-run`, which waits for a real screen (with the TV off the HDMI port reports a generic 1024x768 screen) and opens the game again 10 s after a crash; stop it with `~/.local/bin/outfox-stop` |
| Mouse pointer | hidden while the game window is open (`~/.config/labwc/rc.xml`) |
| OutFox preferences | pump mode, this theme, 1280x720 full screen with vsync, image cache and texture settings that keep the menus at 60 FPS (`config/outfox/Preferences.ini` lists each key) |
| Theme options | `config/outfox/OutFoxPrefs.ini`: UCS, quest and hidden charts hidden, big difficulty ball, etc. |
| Pad mapping | `config/outfox/Keymaps.ini`: player 1 on joystick buttons 1 to 5 and the keys Q E S Z C, player 2 on buttons 6 to 10 and the numeric keypad. Another pad may need mapping again in OutFox's options |
| Profile slots | 6 reserved local profiles that CREATE PROFILE on the profile screen renames (OutFox's Lua cannot create profiles) |
| Theme art | runs `assets.sh` (skip with `--no-assets`) |

Options: `--no-assets` skips the art, `--no-system` skips the steps that need `sudo`.

## The theme's art: `assets.sh`

The art belongs to Andamiro and to the authors of phyrebird and XSanity, so the repository keeps the recipe instead of the files. `assets.sh` downloads it from its sources and builds the rest, into the git-ignored folders the theme reads:

| Folder | Source |
|---|---|
| `Graphics/Phoenix/Channels` | channel cards from [phyrebird](https://github.com/rayden-61/phyrebird), scaled to 320 px; Double 1-4 and 26-28, Single 24-26, Half-Double and category cards made by `tools/make_phoenix_cards.py` |
| `Graphics/Phoenix/CommandWindow` | phyrebird's command window; the sharp category labels made by `tools/make_phoenix_labels.py` |
| `Graphics/Phoenix` | difficulty balls, MY BEST, READY, cursors and arrows from phyrebird; `RecordGrades` too |
| `Graphics/Phoenix/Logo` | the Phoenix 2 logo, cut out by `tools/make_phoenix_logo.py` |
| `Graphics/Phoenix/Title` | the Phoenix 2 title video from YouTube, cut where its attract loop repeats and converted to full-range color, by `assets/title.py` |
| `Graphics/Phoenix/StageBreak` | the Phoenix 2 "HEY! WHY DON'T YOU JUST GET UP AND DANCE MAN?" animation shown when a player breaks the stage, from YouTube, by `assets/stagebreak.py` |
| `Graphics/XSanity`, `Graphics/XSCommandWindow` | from XSanity 0.96.0, downloaded from [xsanity.net](https://xsanity.net/downloads.php) (`--xsanity PATH` uses an install or zip you already have; later versions changed the art and ship fewer noteskins) |
| `~/.project-outfox/NoteSkins/pump` | XSanity's Pump noteskins: the download has 11; the reference Pi has 61, kept in `noteskins-xsanity.zip` (back it up with the songs and pass it with `--noteskins PATH`); XSanity's `default` skin becomes `xs_default` |
| `Graphics/Phoenix/Avatars` | the 165 Phoenix player icons from piugame.com (`PIU 001.png` ..), offered under EDIT PHOTO in profile select, by `assets/avatars.py` |
| `Thumbs` | made from the songs' banners and backgrounds by `tools/make_thumbs.py`, when songs are installed |

Options: `--no-video`, `--no-xsanity`, `--xsanity PATH`, `--noteskins PATH`, `--font TTF`. When a download fails the script carries on and lists what is missing; the theme falls back to its own graphics or text for anything absent.

## Songs

Not included. The theme groups songs by the folder of each version, so name them `NN - NAME` in release order: `01 - 1ST~3RD`, `02 - S.E.~EXTRA`, ... `16 - PHOENIX`, `17 - PHOENIX 2`. A new game opens song select on a random song of the last one. Song backgrounds (BGAs) go inside each song's folder, as usual for OutFox.

## Checks

- `python3 pi/tests/test_display60.py` tests the 60 Hz mode picker, `python3 pi/tests/test_display_watch.py` the screen watcher.
- FPS: OutFox writes one line per second with `:Video, , <fps> FPS` to `~/.project-outfox/Logs/ProjectOutfox.MainLog.*.log` while `ShowStats=1` is set in `Preferences.ini`.
- `~/.cache/display-60hz.log` and `~/.cache/outfox-run.log` show what the screen and autostart scripts did.

## Calibration

`GlobalOffsetSeconds` in `config/outfox/Preferences.ini` was measured on the reference Pi. With other audio hardware, calibrate again in OutFox's options.
