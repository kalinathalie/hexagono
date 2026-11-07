# Hexágono

**English** | [Português (Brasil)](README.pt-BR.md)

A [Project OutFox](https://projectoutfox.com) theme that plays like **Pump It Up Phoenix 2**, forked from [Infinitesimal](https://github.com/Team-Infinitesimal/Infinitesimal). Everything works from the pad, and it is made for a Raspberry Pi 5 at 60 FPS.

![Title screen](.github/readme/title.jpg)

| | |
|---|---|
| ![Profile select](.github/readme/profile-select.jpg) | ![Song select](.github/readme/song-select.jpg) |
| Profile select | Song select |
| ![Group wheel: versions](.github/readme/versions.jpg) | ![Group wheel: categories](.github/readme/categories.jpg) |
| Group wheel: versions | Group wheel: categories |
| ![Difficulty chosen, READY](.github/readme/ready.jpg) | ![Command window](.github/readme/command-window.jpg) |
| Difficulty chosen: MY BEST and READY | Command window |
| ![Co-op gameplay](.github/readme/gameplay.jpg) | ![Result screen](.github/readme/result.jpg) |
| Co-op chart: each player's notes in their color | Result screen |

## Install

### Raspberry Pi 5

1. Write **Raspberry Pi OS (64-bit)** with the desktop to a microSD card using [Raspberry Pi Imager](https://www.raspberrypi.com/software/); in its settings, set a user, a password and the Wi-Fi. Boot the Pi.
2. Open the Terminal (or SSH in) and run:

   ```bash
   git clone https://github.com/kalinathalie/hexagono.git ~/.project-outfox/Themes/Infinitesimal && bash ~/.project-outfox/Themes/Infinitesimal/pi/setup.sh
   ```

   It takes about 20 minutes: Project OutFox, the theme and its art, 60 Hz on any screen, the game opening at login and the pad mapping. Accept the Microsoft fonts license when asked. If it ends with warnings, run `bash ~/.project-outfox/Themes/Infinitesimal/pi/setup.sh` again later.
3. Copy your songs to `~/.project-outfox/Songs`, one folder per version (like `17 - PHOENIX 2`), and build the wheel thumbnails:

   ```bash
   cd ~/.project-outfox/Themes/Infinitesimal && python3 tools/make_thumbs.py
   ```

4. Restart with `sudo reboot`: the game opens by itself on the title screen.

Every step in detail: [Raspberry Pi kit](pi/README.md).

### Other computers

Needs [Project OutFox](https://projectoutfox.com/downloads) 0.5.0-pre043 or newer, in `pump` mode. Clone the theme into OutFox's Themes folder as `Infinitesimal`, build its art (Linux, with Python 3, Pillow, numpy, ffmpeg and node) and pick the theme in OutFox's options:

```bash
git clone https://github.com/kalinathalie/hexagono.git ~/.project-outfox/Themes/Infinitesimal
bash ~/.project-outfox/Themes/Infinitesimal/pi/assets.sh
```

The art of Pump It Up, phyrebird, XSanity and the LBPIU scoreboard is not in this repository: `assets.sh` downloads and builds it on your machine.

## Secret codes

↖ ↗ are the red upper panels, ↙ ↘ the blue lower ones and ● the yellow center. Step them with less than 2 seconds between panels.

| Where | Panels | What it does |
|---|---|---|
| Title screen | ↖ ↗ ↙ ↘ ↖ ↗ ↙ ↘ | Operator options: pad mapping, theme options, CPU AutoPlay |
| Profile select | ↙ ↘ ↙ ↘ ↙ ↘ | Edit the profile's name or photo |
| Song select | ↙ ↘ ↙ ↘ ↙ ↘ | Command window: speed, Auto Velocity, display, noteskin, judge (works while choosing the difficulty too) |
| Basic Mode song select | ↙ ↖ ● ↗ ↘ ↗ ● ↖ ↙ | Switch to the full song select |

## Credits

Infinitesimal by dj505, SheepyChris and the team in `credits.txt`; corner arrows and wheel frame from InfiniteWorlds by tiny-goat. Pump It Up and its art belong to Andamiro. License: GPL-3.0, see `LICENSE`.
