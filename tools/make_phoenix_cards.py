#!/usr/bin/env python3
"""Extra Phoenix-style channel cards for the group select screen.

Phoenix has no channel cards for Double levels 1-4, Half-Double levels or the
sorting categories (Single, Double, Versions, ...). This script makes them in
the same style from the Phoenix cards kept locally in Graphics/Phoenix/Channels
(never in the public repo):

  C_DLV_01..04    the Double Lv. 5 card with the "Lv. N" line of the Single Lv. N
                  card, recolored from red to green
  C_DLV_26..28    the Double Lv. 25 card with its last digit replaced by the 6, 7
                  or 8 of the Double Lv. 26 (over), 17 and 18 cards (Phoenix only
                  has one "over 26" card)
  C_LV_24..26     the same for Single: the Lv. 23 card with the 4, 5 or 6 of the
                  Single Lv. 24 (over), 15 and 16 cards
  C_HDLV_01..28   the Double Lv. N cards recolored to cyan with a "HALF" tag,
                  like the "OVER" tag of the Double Lv. 26 card
  CAT_*.png       category cards: the blank card background recolored per
                  category with the category name; CAT_DOUBLE is Phoenix's own
                  "DOUBLE DIFFICULTY ZONE" card

Inputs in the channels folder: C_LV_01..23, C_LV_24O, C_DLV_05..25, C_DLV_26O,
BLANK_RED.png (the text-free card background) and ZONE_DOUBLE.png. Text uses a bold italic TTF
(Phoenix uses Plateia Bold; Verdana Bold Italic, widened, is the closest
Windows font).

Usage:  python tools/make_phoenix_cards.py [--channels DIR] [--font TTF]
"""
import argparse
import os
from collections import deque

import numpy as np

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


def _ink(a):
    """White text pixels of a card (RGBA float array)."""
    rgb = a[..., :3]
    lum = rgb.mean(axis=2)
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    return (lum > 150) & (sat < 60) & (a[..., 3] > 200)


def _dilate(mask, r):
    return np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(2 * r + 1))) > 0


def _glyphs(ink, y0, y1):
    """Column ranges of the glyphs of one text line."""
    cols = np.nonzero(ink[y0:y1].sum(axis=0) > 0)[0]
    groups, start = [], cols[0]
    for a, b in zip(cols, cols[1:]):
        if b - a > 2:
            groups.append((start, a + 1))
            start = b
    groups.append((start, cols[-1] + 1))
    return groups


def _clean_background(cards):
    """Background of a series of level cards without their text. The cards of a
    series share the same background pixel for pixel, so each pixel comes from the
    cards that have no text there."""
    covered = {k: _dilate(_ink(a), 6) for k, a in cards.items()}
    stack = np.stack([cards[k] for k in cards]); free = np.stack([~covered[k] for k in cards])
    weight = free[..., None].astype(np.float64)
    bg = (stack * weight).sum(axis=0) / np.maximum(weight.sum(axis=0), 1)
    # pixels with text on every card (the neon frame lines) are the same on all of them
    none_free = weight.sum(axis=0)[..., 0] == 0
    bg[none_free] = np.median(stack, axis=0)[none_free]
    return bg


def _paste_text(out, src, bg, region, dx, shadow=None):
    """Lay the text of src inside region (white letters and their dark shadow,
    measured against the clean background) over out, dx pixels to the right.
    With a shadow mask, dark pixels are laid only inside it."""
    for y, x in zip(*np.nonzero(region)):
        tx = x + dx
        if not (0 <= tx < out.shape[1]):
            continue
        d = src[y, x, :3] - bg[y, x, :3]
        if d.mean() < 0 and shadow is not None and not shadow[y, x]:
            continue
        c = np.full(3, 255.0) if d.mean() >= 0 else np.zeros(3)   # white text or dark shadow
        denom = np.abs(c - bg[y, x, :3]).max()
        alpha = 0.0 if denom < 1 else min(1.0, np.abs(d).max() / denom)
        out[y, tx, :3] = out[y, tx, :3] * (1 - alpha) + c * alpha


def _save(out, ch, name):
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA").save(os.path.join(ch, name + ".png"))


def double_high_levels(ch):
    """Double Lv. 26-28: the Double Lv. 25 card over the clean background, with a
    new last digit laid over it."""
    cards = {n: np.asarray(load(ch, "C_DLV_%02d" % n)).astype(np.float64) for n in range(5, 26)}
    cards["26O"] = np.asarray(load(ch, "C_DLV_26O")).astype(np.float64)
    bg = _clean_background(cards)
    y0, y1 = 168, 212                     # the "Lv. NN" line
    unit_x = 216                          # the units digit of "Lv. 2N" starts here (the 6 of "over 26")
    cols = np.arange(cards[25].shape[1])[None, :]

    def unit_glyph(key):
        """Ink of the last digit of a card's level line (wider than the frame line at x 272)."""
        groups = [g for g in _glyphs(_ink(cards[key]), y0, y1) if g[1] - g[0] > 10]
        left = max(unit_x, groups[-1][0]) if key in (25, "26O") else groups[-1][0]
        band = np.zeros(cards[key].shape[:2], bool); band[y0 - 6:y1 + 8] = True
        return _ink(cards[key]) & band & (cols >= left) & (cols < 270), left

    ink5, left5 = unit_glyph(25)
    erase = _dilate(ink5, 4)
    clean = cards[25].copy(); clean[erase] = bg[erase]
    for n, key in ((26, "26O"), (27, 17), (28, 18)):
        ink, left = unit_glyph(key)
        out = clean.copy()
        _paste_text(out, cards[key], bg, _dilate(ink, 5), left5 - left)
        _save(out, ch, "C_DLV_%02d" % n)


def _components(mask):
    """4-connected pixel groups of a mask, as (rows, cols) arrays."""
    seen = np.zeros(mask.shape, bool)
    groups = []
    for y, x in zip(*np.nonzero(mask)):
        if seen[y, x]:
            continue
        seen[y, x] = True
        todo, pts = deque([(y, x)]), []
        while todo:
            cy, cx = todo.popleft()
            pts.append((cy, cx))
            for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                if 0 <= ny < mask.shape[0] and 0 <= nx < mask.shape[1] and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    todo.append((ny, nx))
        pts = np.array(pts)
        groups.append((pts[:, 0], pts[:, 1]))
    return groups


def _last_digit(a, y0, y1):
    """Ink of the last digit of a card's "Lv. NN" line, the column it starts at and
    the other ink around the line. The digits are italic and share columns, so they
    are told apart by connected pixels; frame lines are thinner or shorter."""
    ink = _ink(a)
    band = np.zeros(ink.shape, bool); band[y0:y1] = True
    tall = [g for g in _components(ink & band) if np.ptp(g[0]) >= (y1 - y0) * 0.8 and np.ptp(g[1]) >= 8]
    rows, cols = max(tall, key=lambda g: g[1].min())
    digit = np.zeros(ink.shape, bool); digit[rows, cols] = True
    near = np.zeros(ink.shape, bool); near[y0 - 6:y1 + 8] = True
    return digit, cols.min(), ink & near & ~digit


def _own_area(glyph, others, r):
    """Pixels up to r away from glyph that are not closer to the other ink: the
    glyph's edge and shadow without its neighbor's (the "1" of "Lv. 15" is 1 px
    away from the 5)."""
    mine, theirs = glyph.copy(), others.copy()
    for _ in range(r):
        grown = _dilate(mine, 1) & ~theirs
        theirs = theirs | (_dilate(theirs, 1) & ~grown)
        mine = mine | grown
    return mine


def _cast(glyph, right, down):
    """Where a glyph's drop shadow can fall: the level digits cast it to the right
    and down."""
    out = glyph.copy()
    h, w = glyph.shape
    for dy in range(down + 1):
        for dx in range(right + 1):
            out[dy:, dx:] |= glyph[:h - dy, :w - dx]
    return out


def single_high_levels(ch):
    """Single Lv. 24-26: the Single Lv. 23 card over the clean background, with the
    4 of the Lv. 24 (over) card or the 5 and 6 of the Lv. 15 and 16 cards as the last
    digit (Phoenix only has one "over 24" card)."""
    cards = {n: np.asarray(load(ch, "C_LV_%02d" % n)).astype(np.float64) for n in (14, 15, 16, 23)}
    cards["24O"] = np.asarray(load(ch, "C_LV_24O")).astype(np.float64)
    # every Single card has a digit around x 205-250, so the background can't be
    # rebuilt from them as for Double; the red blank card is that same background
    bg = np.asarray(load(ch, "BLANK_RED").resize(CARD, Image.LANCZOS)).astype(np.float64)
    y0, y1 = 172, 206                     # the "Lv. NN" line
    digit3, _, rest3 = _last_digit(cards[23], y0, y1)
    clean = cards[23].copy()
    erase = _own_area(digit3, rest3, 6)
    clean[erase] = bg[erase]
    # "Lv. 1N" is centered, so its last digit sits further left than in "Lv. 2N";
    # the 4, which both the 14 and the 24 cards have, gives the distance
    shift = _last_digit(cards["24O"], y0, y1)[1] - _last_digit(cards[14], y0, y1)[1]
    for n, key, dx in ((24, "24O", 0), (25, 15, shift), (26, 16, shift)):
        digit, _, rest = _last_digit(cards[key], y0, y1)
        out = clean.copy()
        # only the digit's own shadow: left of the 5 and the 6 lies the shadow of the "1"
        _paste_text(out, cards[key], bg, _own_area(digit, rest, 6), dx, shadow=_cast(digit, 6, 4))
        _save(out, ch, "C_LV_%02d" % n)


def half_double_levels(ch, font_path):
    """Half-Double Lv. N: the Double card in cyan with a "HALF" tag (Phoenix has none)."""
    font = ImageFont.truetype(font_path, 27)
    for n in range(1, 29):
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
    double_high_levels(a.channels)
    single_high_levels(a.channels)
    half_double_levels(a.channels, a.font)
    category_cards(a.channels, a.font)
    print("cards written to", a.channels)


if __name__ == "__main__":
    main()
