#!/usr/bin/env python3
"""Extra Phoenix-style channel cards for the group select screen.

Phoenix has no channel cards for Double levels 1-4, Half-Double levels or the
sorting categories (Single, Double, Versions, ...). This script makes them in
the same style from the Phoenix cards kept locally in Graphics/Phoenix/Channels
(never in the public repo):

  C_DLV_01..04    the Double Lv. 5 card with the "Lv. N" line of the Single Lv. N
                  card, recolored from red to green
  C_HDLV_01..25   the Double Lv. N cards recolored to cyan with a "HALF" tag,
                  like the "OVER" tag of the Double Lv. 26 card
  CAT_*.png       category cards: the blank card background recolored per
                  category with the category name; CAT_DOUBLE is Phoenix's own
                  "DOUBLE DIFFICULTY ZONE" card

Inputs in the channels folder: C_LV_01..04, C_DLV_05..25, BLANK_RED.png (the
text-free card background) and ZONE_DOUBLE.png. Text uses a bold italic TTF
(Phoenix uses Plateia Bold; Verdana Bold Italic, widened, is the closest
Windows font).

Usage:  python tools/make_phoenix_cards.py [--channels DIR] [--font TTF]
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

CARD = (320, 318)          # size of the Phoenix channel cards
WIDEN = 1.15               # Plateia is an extended face


def load(folder, name):
    return Image.open(os.path.join(folder, name + ".png")).convert("RGBA")


def hue_shift(im, degrees):
    alpha = im.getchannel("A")
    h, s, v = im.convert("RGB").convert("HSV").split()
    h = h.point(lambda x: (x + int(degrees / 360 * 256)) % 256)
    out = Image.merge("HSV", (h, s, v)).convert("RGB")
    out.putalpha(alpha)
    return out


def text_image(text, font, fill, stroke=0, stroke_fill=(0, 0, 0, 255), shadow=True):
    """Text as an RGBA image: widened, slanted like the Phoenix cards, with a soft drop shadow."""
    box = font.getbbox(text, stroke_width=stroke)
    w, h = box[2] - box[0] + 40, box[3] - box[1] + 40
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(layer).text((20 - box[0], 20 - box[1]), text, font=font, fill=fill,
                               stroke_width=stroke, stroke_fill=stroke_fill)
    layer = layer.resize((int(w * WIDEN), h), Image.LANCZOS)
    if shadow:
        sh = Image.new("RGBA", layer.size, (0, 0, 0, 0))
        sh.putalpha(layer.getchannel("A").point(lambda a: int(a * 0.85)))
        sh = sh.filter(ImageFilter.GaussianBlur(4))
        base = Image.new("RGBA", (layer.size[0] + 8, layer.size[1] + 8), (0, 0, 0, 0))
        base.alpha_composite(sh, (6, 7))
        base.alpha_composite(layer, (0, 0))
        layer = base
    return layer.crop(layer.getbbox())


def paste_center(canvas, im, cx, cy, max_w=None):
    if max_w and im.size[0] > max_w:
        im = im.resize((max_w, int(im.size[1] * max_w / im.size[0])), Image.LANCZOS)
    canvas.alpha_composite(im, (int(cx - im.size[0] / 2), int(cy - im.size[1] / 2)))


def tag(canvas, text, font, color, cx, cy, angle=10, max_w=None, stroke=4):
    """A colored, tilted tag like Phoenix's "OVER": bright fill, dark outline."""
    dark = tuple(int(c * 0.25) for c in color[:3]) + (255,)
    im = text_image(text, font, color, stroke=stroke, stroke_fill=dark, shadow=False)
    if max_w and im.size[0] > max_w:
        im = im.resize((max_w, int(im.size[1] * max_w / im.size[0])), Image.LANCZOS)
    im = im.rotate(angle, resample=Image.BICUBIC, expand=True)
    canvas.alpha_composite(im, (int(cx - im.size[0] / 2), int(cy - im.size[1] / 2)))


def to_card(im):
    """Scale to the channel card size, keeping the whole art (wider art gets letterboxed)."""
    scale = min(CARD[0] / im.size[0], CARD[1] / im.size[1])
    small = im.resize((round(im.size[0] * scale), round(im.size[1] * scale)), Image.LANCZOS)
    out = Image.new("RGBA", CARD, (0, 0, 0, 0))
    out.alpha_composite(small, ((CARD[0] - small.size[0]) // 2, (CARD[1] - small.size[1]) // 2))
    return out


def double_low_levels(ch):
    """Double Lv. 1-4: swap the "Lv. 5" line of the Double card for the Single card's line."""
    d5 = load(ch, "C_DLV_05")
    mask = Image.new("L", d5.size, 0)
    mask.paste(255, (54, 165, 266, 214))            # inside the frame, the "Lv. N" line only
    mask = mask.filter(ImageFilter.GaussianBlur(3))
    for n in range(1, 5):
        single = hue_shift(load(ch, "C_LV_%02d" % n), 120)
        # the Single line sits 3 px lower than the Double one
        single = single.transform(single.size, Image.AFFINE, (1, 0, 0, 0, 1, 3), resample=Image.BICUBIC)
        Image.composite(single, d5, mask).save(os.path.join(ch, "C_DLV_%02d.png" % n))


def half_double_levels(ch, font_path):
    """Half-Double Lv. N: the Double card in cyan with a "HALF" tag (Phoenix has none)."""
    font = ImageFont.truetype(font_path, 27)
    for n in range(1, 26):
        src = os.path.join(ch, "C_DLV_%02d.png" % n)
        if not os.path.exists(src):
            continue
        card = hue_shift(Image.open(src).convert("RGBA"), 60)
        # between the two lines, over the start of "Lv.", like "OVER"
        tag(card, "HALF", font, (70, 235, 255, 255), 60, 166, angle=11, stroke=3)
        card.save(os.path.join(ch, "C_HDLV_%02d.png" % n))


# category: (hue shift from red, first line, second line, tag text, tag color)
CATEGORIES = {
    "CAT_SINGLE": (0, "DIFFICULTY", "ZONE", "SINGLE", (255, 60, 50, 255)),
    "CAT_HALFDOUBLE": (180, "DIFFICULTY", "ZONE", "HALF-DOUBLE", (70, 235, 255, 255)),
    "CAT_SPECIAL": (275, "SPECIAL", "ZONE", None, None),
    "CAT_VERSIONS": (305, "PUMP IT UP", "VERSIONS", None, None),
    "CAT_TITLE": (215, "TITLE", "A ~ Z", None, None),
    "CAT_ARTIST": (28, "ARTIST", "A ~ Z", None, None),
}


def category_cards(ch, font_path):
    blank = load(ch, "BLANK_RED")
    big, small, tag_font = (ImageFont.truetype(font_path, s) for s in (70, 52, 50))
    cx = blank.size[0] / 2
    for name, (hue, line1, line2, tag_text, tag_color) in CATEGORIES.items():
        card = hue_shift(blank, hue)
        # the longer line gets the smaller size, as on the Phoenix cards
        f1, f2 = (small, big) if len(line1) > len(line2) else (big, small)
        y1, y2 = (232, 346) if tag_text else (248, 330)
        paste_center(card, text_image(line1, f1, (255, 255, 255, 255)), cx, y1, max_w=540)
        paste_center(card, text_image(line2, f2, (255, 255, 255, 255)), cx, y2, max_w=540)
        if tag_text:
            tag(card, tag_text, tag_font, tag_color, 160, 290, angle=10, max_w=300)
        to_card(card).save(os.path.join(ch, name + ".png"))
    to_card(load(ch, "ZONE_DOUBLE")).save(os.path.join(ch, "CAT_DOUBLE.png"))


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--channels", default=os.path.join(here, "Graphics", "Phoenix", "Channels"))
    ap.add_argument("--font", default="C:/Windows/Fonts/verdanaz.ttf")
    a = ap.parse_args()
    double_low_levels(a.channels)
    half_double_levels(a.channels, a.font)
    category_cards(a.channels, a.font)
    print("cards written to", a.channels)


if __name__ == "__main__":
    main()
