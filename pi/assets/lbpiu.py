#!/usr/bin/env python3
"""Downloads the Phoenix 2 result screen art published by the LBPIU scoreboard
(scoreboard.lbpiu.com.br, files/skins/phoenix2) into Graphics/Phoenix/Scoreboard, and
builds from it what the theme loads. Only the pieces that match the game better than
the theme's other sources (compared with a Phoenix 2 result video) are taken:

  Plates/<PLATE>.png      the 8 plates, PG.png ... RG.png renamed ("ULTIMATE GAME.png")
  Balls/S05.png ...       the chart balls with their level: SINGLE and DOUBLE 1-29,
                          CO-OP x2-x5
  Digits/                 the score digits n0-n9.png as a font ("Score digits"), where
                          z is a dim zero for the leading zeros
  Labels/_perfect.png ... PERFECT to KCAL and SCORE, drawn with the scoreboard's font
                          (Gorehand.otf) in its colors: a vertical gradient, a dark
                          outline and a shadow
  info.ini                written last

The grades stay the ones cut from the result video (grades.py): they are as good.
Needs Pillow. Usage: python3 lbpiu.py THEME_DIR
"""
import io
import os
import sys
import time
import urllib.error
import urllib.request

from PIL import Image, ImageDraw, ImageFilter, ImageFont

BASE = "https://scoreboard.lbpiu.com.br/files/skins/phoenix2/"
PLATES = {"PG": "PERFECT GAME", "UG": "ULTIMATE GAME", "EG": "EXTREME GAME", "SG": "SUPERB GAME",
          "MG": "MARVELOUS GAME", "TG": "TALENTED GAME", "FG": "FAIR GAME", "RG": "ROUGH GAME"}
# (file, text, top color, bottom color): the scoreboard's CSS gradients
LABELS = [
    ("_perfect", "PERFECT", (17, 238, 238), (0, 136, 204)),
    ("_great", "GREAT", (153, 221, 34), (34, 204, 17)),
    ("_good", "GOOD", (255, 255, 51), (204, 170, 17)),
    ("_bad", "BAD", (238, 17, 238), (170, 0, 204)),
    ("_miss", "MISS", (204, 170, 51), (204, 17, 0)),
    ("_maxcombo", "MAX COMBO", (255, 255, 255), (153, 153, 153)),
    ("_cal", "KCAL", (255, 255, 255), (153, 153, 153)),
    ("_score", "SCORE", (255, 255, 255), (225, 225, 225)),
]
CELL, DIGIT_W = 64, 50   # digit font: 64 px cells, the 50 px wide digits side by side
DIGIT_ROWS = ["0123", "4567", "89z,", " .+-"]
LABEL_CAP = 54           # label cap height in pixels (the theme shows them at a third)
OUTLINE, SHADOW = 3, 3   # label outline width and shadow offset, in pixels
USER_AGENT = "hexagono-theme-assets"


def ball_names():
    return (["S%02d" % n for n in range(1, 30)] + ["D%02d" % n for n in range(1, 30)]
            + ["C%02d" % n for n in range(2, 6)])


def fetch(name, tries=4):
    """The file's bytes, or None when the scoreboard does not have it (404)."""
    req = urllib.request.Request(BASE + urllib.request.quote(name), headers={"User-Agent": USER_AGENT})
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            if attempt == tries - 1:
                raise
        except OSError:
            if attempt == tries - 1:
                raise
        time.sleep(2 + attempt * 3)


def fetch_image(name):
    data = fetch(name)
    if data is None:
        return None
    im = Image.open(io.BytesIO(data))
    im.load()
    return im.convert("RGBA")


def dim(im, factor):
    r, g, b, a = im.split()
    return Image.merge("RGBA", (r, g, b, a.point(lambda v: round(v * factor))))


def digit_sheet(digits):
    """The 4x4 font sheet: the 10 digits (dict "0".."9" -> image) and z, the 0 at 35%."""
    sheet = Image.new("RGBA", (CELL * 4, CELL * 4), (0, 0, 0, 0))
    glyphs = dict(digits)
    glyphs["z"] = dim(digits["0"], 0.35)
    for row, chars in enumerate(DIGIT_ROWS):
        for col, ch in enumerate(chars):
            im = glyphs.get(ch)
            if im is not None:
                sheet.alpha_composite(im, (col * CELL + (CELL - im.width) // 2, row * CELL + (CELL - im.height) // 2))
    return sheet


def digit_font_ini():
    extra = (CELL - DIGIT_W) // 2
    lines = ["[common]", "Baseline=%d" % (CELL - 1), "Top=1", "LineSpacing=%d" % CELL,
             "DrawExtraPixelsLeft=%d" % extra, "DrawExtraPixelsRight=%d" % extra, "AdvanceExtraPixels=0",
             "", "[numbers]"]
    lines += ["Line %d=%s" % (i, row) for i, row in enumerate(DIGIT_ROWS)]
    lines.append("")
    for i, ch in enumerate("".join(DIGIT_ROWS)):
        lines.append("%d=%d" % (i, DIGIT_W if ch in "0123456789z" else 16))
    return "\n".join(lines) + "\n"


def gradient_fill(mask, top, bottom):
    """The mask's shape in a vertical gradient: top color down to 25% of the height,
    bottom color from 75%, a straight blend between (the scoreboard's CSS)."""
    w, h = mask.size
    strip = Image.new("RGB", (1, h))
    for y in range(h):
        t = min(1.0, max(0.0, (y / max(1, h - 1) - 0.25) / 0.5))
        strip.putpixel((0, y), tuple(round(a * (1 - t) + b * t) for a, b in zip(top, bottom)))
    out = strip.resize((w, h), Image.NEAREST).convert("RGBA")
    out.putalpha(mask)
    return out


def label_image(text, font, top, bottom, cap=LABEL_CAP):
    """The label: letters scaled so the capitals are cap pixels tall, the gradient, a
    dark outline and a shadow to the lower right; cropped tight."""
    probe = Image.new("L", (10, 10))
    box = ImageDraw.Draw(probe).textbbox((0, 0), text, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    pad = OUTLINE + SHADOW + 2
    mask = Image.new("L", (w + 2 * pad, h + 2 * pad), 0)
    ImageDraw.Draw(mask).text((pad - box[0], pad - box[1]), text, font=font, fill=255)
    mask = mask.crop(mask.getbbox())
    scale = cap / mask.height
    mask = mask.resize((max(1, round(mask.width * scale)), cap), Image.LANCZOS)
    canvas = (mask.width + 2 * pad, mask.height + 2 * pad)
    letters = Image.new("L", canvas, 0)
    letters.paste(mask, (pad, pad))
    outline = letters.filter(ImageFilter.MaxFilter(2 * OUTLINE + 1))
    shadow = Image.new("L", canvas, 0)
    shadow.paste(outline, (SHADOW, SHADOW))
    out = Image.new("RGBA", canvas, (0, 0, 0, 0))
    black = Image.new("RGBA", canvas, (0, 0, 0, 255))
    out.paste(black, (0, 0), shadow.point(lambda v: v * 0.6))
    out.paste(black, (0, 0), outline)
    out.alpha_composite(gradient_fill(letters, top, bottom))
    return out.crop(out.getchannel("A").getbbox())


def info_text(balls):
    return "[Scoreboard]\nSource=%s\nBalls=%d\n" % (BASE, balls)


def main():
    out = os.path.join(sys.argv[1], "Graphics", "Phoenix", "Scoreboard")
    for sub in ("Plates", "Balls", "Digits", "Labels"):
        os.makedirs(os.path.join(out, sub), exist_ok=True)

    for short, name in PLATES.items():
        fetch_image(short + ".png").save(os.path.join(out, "Plates", name + ".png"))
    balls = 0
    for name in ball_names():
        im = fetch_image(name + ".png")
        if im is not None:
            im.save(os.path.join(out, "Balls", name + ".png"))
            balls += 1
    digits = {str(d): fetch_image("n%d.png" % d) for d in range(10)}
    digit_sheet(digits).save(os.path.join(out, "Digits", "Score digits [numbers] 4x4.png"))
    with open(os.path.join(out, "Digits", "Score digits.ini"), "w", newline="\n") as f:
        f.write(digit_font_ini())

    font_data = fetch("Gorehand.otf")
    font = ImageFont.truetype(io.BytesIO(font_data), 160)
    for key, text, top, bottom in LABELS:
        label_image(text, font, top, bottom).save(os.path.join(out, "Labels", key + ".png"))

    # last, so a failed run leaves no info.ini and assets.sh runs this again
    with open(os.path.join(out, "info.ini"), "w", newline="\n") as f:
        f.write(info_text(balls))
    print("scoreboard: %d plates, %d balls, 10 digits, %d labels" % (len(PLATES), balls, len(LABELS)))


if __name__ == "__main__":
    main()
