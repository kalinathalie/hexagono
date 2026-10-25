#!/usr/bin/env python3
"""Sharp category labels for the Phoenix command window.

The Phoenix label sheet (Graphics/Phoenix/CommandWindow/MenuIcons 1x9.png, kept
locally, never in the public repo) has 104x42 labels. The command window shows
them at about 1.75x and a 1080p screen scales them again, so they come out
blurry. This script draws the same nine labels at 4x with Montserrat ExtraBold
(the theme's own font) in the Phoenix style: white letters with a colored
outline and a glow of the same color, slanted and stretched to fill the label.
The command window uses "labels 1x9.png" instead of the Phoenix sheet when it
exists; the frames are in the same order.

Usage:  python tools/make_phoenix_labels.py [--out DIR] [--font TTF]
"""
import argparse
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

SCALE = 4
FRAME = (104 * SCALE, 42 * SCALE)    # one label of the Phoenix sheet, at SCALE
BOX = (94 * SCALE, 31 * SCALE)       # area the outlined letters fill, as on the Phoenix sheet
STROKE = int(1.5 * SCALE)
GLOW = int(2.5 * SCALE)
SLANT = 0.18                         # horizontal shear of the one-line labels
BOLDER = 7                           # Phoenix letters are heavier than Montserrat ExtraBold

WHITE = (255, 255, 255)
LABELS = [   # lines, outline/glow color, letter color
    (["SPEED"], (255, 28, 51), WHITE),
    (["DISPLAY"], (255, 110, 24), WHITE),
    (["NOTE SKIN"], (226, 203, 64), WHITE),
    (["PATH"], (73, 202, 119), WHITE),
    (["ALTERNATE"], (75, 218, 253), WHITE),
    (["JUDGE"], (25, 25, 255), WHITE),
    (["RUSH"], (230, 38, 255), WHITE),
    (["RESET"], (255, 28, 51), (255, 226, 21)),
    (["AUTO", "VELOCITY"], (255, 33, 54), WHITE),
]


def text_mask(lines, font):
    """White-on-black mask of the lines, centered on each other, cropped to the ink."""
    asc, desc = font.getmetrics()
    gap = int(asc * 0.12)
    widths = [int(font.getlength(line)) for line in lines]
    w, h = max(widths) + asc, len(lines) * asc + (len(lines) - 1) * gap + desc
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    for i, line in enumerate(lines):
        draw.text(((w - widths[i]) / 2, i * (asc + gap)), line, font=font, fill=255)
    return mask.crop(mask.getbbox())


def slant(mask, amount):
    if amount == 0:
        return mask
    w, h = mask.size
    extra = int(h * amount)
    return mask.transform((w + extra, h), Image.AFFINE, (1, amount, -extra, 0, 1, 0),
                          resample=Image.BICUBIC)


def grow(mask, radius):
    """Round dilation: blur, then keep everything the blur reached."""
    return mask.filter(ImageFilter.GaussianBlur(radius / 2)).point(lambda a: 255 if a > 8 else 0) \
        .filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(1))


def label(lines, color, fill, font):
    ink = slant(text_mask(lines, font), SLANT if len(lines) == 1 else 0)
    inner = (BOX[0] - 2 * STROKE, BOX[1] - 2 * STROKE)
    ink = ink.resize(inner, Image.LANCZOS)

    letters = Image.new("L", FRAME, 0)
    letters.paste(ink, ((FRAME[0] - inner[0]) // 2, (FRAME[1] - inner[1]) // 2))
    letters = letters.filter(ImageFilter.MaxFilter(BOLDER))
    outline = grow(letters, STROKE)
    glow = outline.filter(ImageFilter.GaussianBlur(GLOW))

    out = Image.new("RGBA", FRAME, color + (0,))
    out.putalpha(glow.point(lambda a: min(255, int(a * 1.3))))
    solid = Image.new("RGBA", FRAME, color + (255,))
    out.paste(solid, (0, 0), outline)
    face = Image.new("RGBA", FRAME, fill + (255,))
    out.paste(face, (0, 0), letters)
    # a thin line of the outline color inside the letters' edge, as on Phoenix
    edge = ImageChops.subtract(letters, letters.filter(ImageFilter.MinFilter(SCALE + 1)))
    out.paste(solid, (0, 0), edge.point(lambda a: a * 40 // 100))
    return out


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", default=os.path.join(here, "Graphics", "Phoenix", "CommandWindow"))
    ap.add_argument("--font", default=os.path.join(here, "Fonts", "Montserrat-ExtraBold.ttf"))
    a = ap.parse_args()
    font = ImageFont.truetype(a.font, 200)
    sheet = Image.new("RGBA", (FRAME[0], FRAME[1] * len(LABELS)), (0, 0, 0, 0))
    for i, (lines, color, fill) in enumerate(LABELS):
        sheet.paste(label(lines, color, fill, font), (0, i * FRAME[1]))
    path = os.path.join(a.out, "labels 1x%d.png" % len(LABELS))
    sheet.save(path)
    print("labels written to", path)


if __name__ == "__main__":
    main()
