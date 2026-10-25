#!/usr/bin/env python3
"""Downloads the Phoenix art the theme uses from phyrebird, a Phoenix-style theme
(github.com/rayden-61/phyrebird, folder "Themes/Fiesta 2/Graphics"), into
Graphics/Phoenix:

  Channels/        the channel cards, renamed and scaled to 320 px wide like the
                   theme expects ("DOUBLE OVER LV. 26" -> C_DLV_26O, C_*.png as is),
                   plus ZONE_DOUBLE.png and BLANK_RED.png (the text-free card, a layer
                   of "Fundo Canal Level Channels.psd"), the inputs of
                   tools/make_phoenix_cards.py
  CommandWindow/   the OptionList art of the command window
  *.png            difficulty balls, MY BEST, READY, cursors, hexagons and arrows
  RecordGrades/    the grade icons

Needs Pillow and psd-tools. Usage: python3 phyrebird.py THEME_DIR
"""
import io
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

from PIL import Image

TREE = "https://api.github.com/repos/rayden-61/phyrebird/git/trees/main?recursive=1"
RAW = "https://raw.githubusercontent.com/rayden-61/phyrebird/main/"
BASE = "Themes/Fiesta 2/Graphics/"
CARD_W = 320
COMMAND_WINDOW = ["bg.png", "frame.png", "blue.png", "black.png", "arrows_big.png", "arrows_sm.png",
                  "MenuIcons 1x9.png", "MenuIcons 4x3.png", "icons 11x11.png", "glow_1.png", "glow_2.png"]
SELECT_MUSIC = ["fullbar balls 7x1.png", "blackball.png", "Difficulty_BigBalls 4x2.png",
                "Difficulty_BigBalls_Titles 4x2.png", "Difficulty_BigBalls glow sidetoside.png",
                "my_best_P1.png", "my_best_P2.png", "my_best_glow_P1.png", "my_best_glow_P2.png",
                "READY_P1.png", "READY_P2.png", "fullbar_PlayerNumber_P1_cursor.png",
                "fullbar_PlayerNumber_P2_cursor.png", "groupwheel_br.png", "Hex_Left.png", "Hex_Right.png",
                "glow_ring.png"]
ARROWS = ["UpLeft 4x2.png", "DownLeft 4x2.png", "left_pink.png", "right_pink.png", "left_blue.png", "right_blue.png"]
CARD_PSD = "ChannelsGraphics/Fundo Canal Level Channels.psd"


def fetch(path, tries=4):
    url = RAW + urllib.parse.quote(path)
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                return r.read()
        except OSError:
            if attempt == tries - 1:
                raise
            time.sleep(2 + attempt * 3)


def fetch_image(path, tries=4):
    """An image that decodes completely (raw downloads sometimes arrive cut short)."""
    for attempt in range(tries):
        data = fetch(path)
        try:
            im = Image.open(io.BytesIO(data))
            im.load()
            return data, im
        except OSError:
            if attempt == tries - 1:
                raise
            time.sleep(2)


def save_raw(path, target):
    data, _ = fetch_image(path)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    with open(target, "wb") as f:
        f.write(data)


def card_name(stem):
    """Theme name of a phyrebird channel card, or None for the ones it does not use."""
    m = re.match(r"^DOUBLE\s+(OVER\s+)?LV\.\s*(\d+)$", stem, re.IGNORECASE)
    if m:
        return "C_DLV_%02d%s" % (int(m.group(2)), "O" if m.group(1) else "")
    if stem.upper().startswith("C_"):
        return stem.upper()
    return None


def blank_card(target):
    """The red card without text: the second picture layer of the cards' PSD,
    placed on a transparent canvas the size of the document."""
    from psd_tools import PSDImage
    psd = PSDImage.open(io.BytesIO(fetch(BASE + CARD_PSD)))
    layer = [l for l in psd.descendants() if not l.is_group()][1]
    canvas = Image.new("RGBA", psd.size, (0, 0, 0, 0))
    canvas.alpha_composite(layer.composite().convert("RGBA"),
                           (layer.left, layer.top) if layer.left >= 0 and layer.top >= 0 else (0, 0))
    canvas.save(target)


def main():
    theme = sys.argv[1]
    px = os.path.join(theme, "Graphics", "Phoenix")
    with urllib.request.urlopen(TREE, timeout=60) as r:
        tree = [e["path"] for e in json.load(r)["tree"] if e["type"] == "blob"]

    channels = os.path.join(px, "Channels")
    os.makedirs(channels, exist_ok=True)
    cards = 0
    for path in tree:
        if not path.startswith(BASE + "ChannelsGraphics/") or not path.lower().endswith(".png"):
            continue
        stem = os.path.splitext(os.path.basename(path))[0]
        if stem.upper() == "DOUBLE DIFFICULTY ZONE":
            save_raw(path, os.path.join(channels, "ZONE_DOUBLE.png"))
            continue
        name = card_name(stem)
        if not name:
            continue
        _, im = fetch_image(path)
        im = im.convert("RGBA")
        im.resize((CARD_W, round(im.height * CARD_W / im.width)), Image.LANCZOS).save(os.path.join(channels, name + ".png"))
        cards += 1
    blank_card(os.path.join(channels, "BLANK_RED.png"))
    print("channel cards:", cards)

    for f in COMMAND_WINDOW:
        save_raw(BASE + "OptionList/" + f, os.path.join(px, "CommandWindow", f))
    for f in SELECT_MUSIC:
        save_raw(BASE + "ScreenSelectMusic/" + f, os.path.join(px, f))
    for f in ARROWS:
        save_raw(BASE + "ScreenSelectMusic/_Arrows/" + f, os.path.join(px, f))
    grades = [p for p in tree if p.startswith(BASE + "RecordGrades/") and p.lower().endswith(".png")]
    for path in grades:
        save_raw(path, os.path.join(px, "RecordGrades", os.path.basename(path)))
    print("command window:", len(COMMAND_WINDOW), "select music:", len(SELECT_MUSIC) + len(ARROWS), "grades:", len(grades))


if __name__ == "__main__":
    main()
