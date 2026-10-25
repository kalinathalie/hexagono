# Raspberry Pi kit

**English** | [Português (Brasil)](README.pt-BR.md)

Everything needed to turn a Raspberry Pi 5 into the reference machine: Project OutFox, this theme with all of its art, the screen and autostart setup, the preferences and the pad mapping. Songs are not part of it.

## Steps

1. Write **Raspberry Pi OS (64-bit) with desktop** to the card with Raspberry Pi Imager (tested with the release based on Debian 13 "trixie"), boot it and connect it to the internet. Any user name works, and `git` comes with the system.
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

5. Optional, more noteskins: the XSanity download brings 11 Pump noteskins and OutFox has 6 of its own. The reference Pi has 61, from a personal collection kept in `noteskins-xsanity.zip` that is not published (the skins are Andamiro's art). Any set of Pump noteskins installs the same way, from a folder or zip with a `pump` folder inside, and gets the same fixes as XSanity's:

   ```bash
   bash ~/.project-outfox/Themes/Infinitesimal/pi/assets.sh --noteskins ~/noteskins.zip
   ```

6. Reboot. The Pi logs in to the desktop and the game opens on its own, at 60 Hz on whatever screen is connected. After quitting the game, the **Pump It Up (OutFox)** icon on the desktop opens it again.
7. If your pad is not like the reference one (a USB adapter that shows both pads as one joystick, player 1 on buttons 1 to 5 and player 2 on 6 to 10; `config/outfox/Keymaps.ini` has each panel's button), map it under INPUT OPTIONS in OutFox's options. To open them from the title screen, press red left, red right, blue left, blue right, twice. Until the pad works you can use the keyboard: player 1 is Q, E, S, Z, C (up-left, up-right, center, down-left, down-right).

Both scripts can be run again at any time: they skip what is already in place, and keep any file they replace as `*.bak-hexagono`.

## What `setup.sh` does

| Step | Result |
|---|---|
| System (`sudo`) | desktop autologin, no screen blanking; packages: git, curl, ffmpeg, Python with Pillow and numpy, nodejs, grim, wlr-randr, kanshi, Microsoft fonts (optional) |
| Project OutFox | 0.5.0-pre043 for Raspberry Pi, in `~/ProjectOutFox` |
| Screen | `~/.local/bin/display-60hz` picks the best 60 Hz mode up to about 1080p on every screen (TVs often prefer 4K at 30 Hz, which caps the game at 30 FPS); run at login and by kanshi whenever a screen is connected. `~/.local/bin/display-watch` checks the screens every 2 s for what kanshi misses, like a TV that was off at boot being turned on (it jumps to its preferred 4K at 30 Hz): it puts it back at 60 Hz and restarts the game if it was opened on another screen or if the screen went away meanwhile (turning a TV on can drop the HDMI output for a moment) |
| Autostart | `~/.config/labwc/autostart` starts display-watch and opens the game through `~/.local/bin/outfox-run`, which waits for a real screen (with the TV off the HDMI port reports a generic 1024x768 screen) and opens the game again 10 s after a crash; stop it with `~/.local/bin/outfox-stop`. The desktop gets a Pump It Up (OutFox) icon that runs outfox-run too |
| Mouse pointer | hidden while the game window is open (`~/.config/labwc/rc.xml`) |
| OutFox preferences | pump mode, this theme, 1280x720 full screen with vsync, image cache and texture settings that keep the menus at 60 FPS (`config/outfox/Preferences.ini` lists each key). `merge_prefs.py` sets only those keys, where OutFox keeps them, including the `[Game-pump]` section: OutFox takes the theme of the current game from there at start, so without it a new install opens OutFox's default theme |
| Theme options | `config/outfox/OutFoxPrefs.ini`: UCS, quest and hidden charts hidden, big difficulty ball, a difficulty list that wraps around at both ends, etc. |
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
| `~/.project-outfox/NoteSkins/pump` | XSanity's Pump noteskins: the download has 11; the reference Pi has 61, from a personal collection kept in `noteskins-xsanity.zip` that is not published (back it up with the songs; `--noteskins PATH` installs it or any other set); XSanity's `default` skin becomes `xs_default`; explosions that only played during a combo also play on the first note and after a miss |
| `Graphics/Phoenix/Avatars` | the 165 Phoenix player icons from piugame.com (`PIU 001.png` ..), offered under EDIT PHOTO in profile select, by `assets/avatars.py` |
| `Thumbs` | made from the songs' banners and backgrounds by `tools/make_thumbs.py`, when songs are installed |

Options: `--no-video`, `--no-xsanity`, `--xsanity PATH`, `--noteskins PATH`, `--font TTF`. When a download fails the script carries on and lists what is missing; the theme falls back to its own graphics or text for anything absent.

## Songs

Not included. The theme groups songs by the folder of each version, so name them `NN - NAME` in release order: `01 - 1ST~3RD`, `02 - S.E.~EXTRA`, ... `16 - PHOENIX`, `17 - PHOENIX 2`. A new game opens song select on a random song of the last one. Song backgrounds (BGAs) go inside each song's folder, as usual for OutFox.

## Compared with the reference Pi

A Pi set up with these steps opens the same game: the theme with its art, title video, stage break animation and player icons, the screen and autostart setup, the preferences and the profile slots. What it does not bring:

- **Songs and their BGAs**: your own, laid out as in [Songs](#songs).
- **Noteskins**: 11 from XSanity plus OutFox's 6, instead of the reference Pi's 61, unless you install a set of your own (step 5).
- **Profiles, scores and each player's options**: personal data in `~/.project-outfox/Save`. To take them to another Pi, copy `Save/LocalProfiles` and `Save/MachineProfile` with the game closed.
- **Category cards and labels**: in Verdana only when Microsoft's font license is accepted; otherwise in DejaVu Sans.
- **Audio sync**: measured on the reference Pi (see [Calibration](#calibration)).

The art comes from GitHub (phyrebird), YouTube, xsanity.net and piugame.com: when one of them is down, `assets.sh` lists what is missing and can be run again later.

## Checks

- `python3 pi/tests/test_<name>.py`, one per part: `display60` (60 Hz mode picker), `display_watch` (screen watcher), `merge_prefs` (preferences), `title` (title video timings), `noteskins` (explosion fix), `avatars` (player icons).
- FPS: OutFox writes one line per second with `:Video, , <fps> FPS` to `~/.project-outfox/Logs/ProjectOutfox.MainLog.*.log` while `ShowStats=1` is set in `Preferences.ini`.
- `~/.cache/display-60hz.log` and `~/.cache/outfox-run.log` show what the screen and autostart scripts did.

## Calibration

`GlobalOffsetSeconds` in `config/outfox/Preferences.ini` was measured on the reference Pi. With other audio hardware, calibrate again in OutFox's options.
