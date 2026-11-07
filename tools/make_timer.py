#!/usr/bin/env python3
"""Draws the menu timer of the top HUD after the one Phoenix 2 shows, as the theme's own
art (measured on a 1080p video of it):

  Graphics/UI/Timer frame.png     the yellow frame (straight top, sides narrowing toward
                                  the bottom, a shallow V under the digits) around a
                                  smoky green inside, darker behind the digits
  Graphics/UI/Timer smoke.png     a second smoke for the inside only; the HUD fades it in
                                  and out over the frame so the smoke moves
  Fonts/Timer digits [numbers] 4x4.png, Fonts/Timer digits.ini
                                  white squared digits with a thick black outline and a
                                  dark halo, a 4x4 grid of 128 px cells

Usage: python tools/make_timer.py [THEME_DIR]
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# --- Frame, in 1080p pixels of the video: u is the distance from the screen center, y
# from the top. The image covers u -75..75 and y 2..93 (the HUD shows it at 2/3).
U0, U1, Y0, Y1 = -75, 75, 2, 93
SCALE = 2          # output pixels per video pixel
SS = 8             # supersampling while drawing
TOP, SIDE, BOTTOM = 4, 10, 5   # frame thickness: top, sides, bottom


def half_width(y):
    """Outer half width of the frame at height y: 72, narrowing to 63 at the bottom."""
    return 72 - 9 * np.clip((y - 25) / 65, 0, 1)


def bottom(u):
    """Outer bottom edge: 90 at the corners, rising to 84 under the digits."""
    return 90 - 6 * np.maximum(0, 1 - np.abs(u) / 58)


def grid(per_unit):
    w, h = (U1 - U0) * per_unit, (Y1 - Y0) * per_unit
    y, x = np.mgrid[0:h, 0:w].astype(np.float64)
    return U0 + (x + 0.5) / per_unit, Y0 + (y + 0.5) / per_unit


def soft(mask, sigma):
    """A mask (bool array) blurred by sigma pixels, as floats 0..1."""
    im = Image.fromarray((mask * 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(sigma)), dtype=np.float64) / 255


def shape(u, y, inset_top, inset_side, inset_bottom, round_px):
    raw = (y >= 5 + inset_top) & (y <= bottom(u) - inset_bottom) & (np.abs(u) <= half_width(y) - inset_side)
    return soft(raw, round_px) >= 0.5   # blurring and cutting at half rounds the corners


def noise(h, w, seed):
    """Smoke: a few octaves of smooth value noise, 0..1."""
    rng = np.random.default_rng(seed)
    total = np.zeros((h, w))
    for cells, weight in ((5, 0.5), (10, 0.3), (20, 0.2)):
        small = rng.random((max(2, h * cells // w + 2), cells + 2))
        im = Image.fromarray((small * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        total += weight * np.asarray(im, dtype=np.float64) / 255
    return np.clip((total - total.min()) / (total.max() - total.min()), 0, 1)


def inside_color(u, y, smoke):
    t = np.clip((y - 9) / 76, 0, 1)[..., None]
    base = (1 - t) * np.array([22, 218, 62]) + t * np.array([46, 252, 116])
    center = 1 - 0.75 * np.exp(-((u / 30) ** 2 + ((y - 43) / 16) ** 2))
    return base * (0.62 + 0.38 * smoke)[..., None] * center[..., None]


def frame_images():
    per = SCALE * SS
    u, y = grid(per)
    outer = shape(u, y, 0, 0, 0, 1.5 * per)
    inner = shape(u, y, TOP, SIDE, BOTTOM, 1.0 * per)
    h, w = u.shape
    smoke_a, smoke_b = noise(h, w, 7), noise(h, w, 11)

    color = inside_color(u, y, smoke_a)
    # a dark green line just inside the frame
    near_inner = soft(inner, 1.2 * per)
    line = (near_inner < 0.97) & inner
    color[line] = color[line] * 0.35 + np.array([48, 200, 48]) * 0.65
    # the frame: yellow, a light line along the bottom edge, a dark olive outer edge
    ring = outer & ~inner
    lit = (y > bottom(u) - 3.2) & (y < bottom(u) - 1.2)
    yellow = np.where(lit[..., None], np.array([236, 252, 120]), np.array([236, 253, 0]))
    edge = np.clip((soft(outer, 1.2 * per) - 0.5) / 0.45, 0, 1)[..., None]
    rim = edge * yellow + (1 - edge) * np.array([120, 130, 8])
    color = np.where(ring[..., None], rim, color)

    def save(rgb, alpha, path):
        rgba = np.dstack([np.clip(rgb, 0, 255), alpha * 255]).astype(np.uint8)
        im = Image.fromarray(rgba, "RGBA")
        im.resize((w // SS, h // SS), Image.LANCZOS).save(path)

    smoke = inside_color(u, y, smoke_b)
    smoke[line] = color[line]
    return (color, outer.astype(np.float64)), (smoke, inner.astype(np.float64)), save


# --- Digits, in glyph units: 90 wide, 100 tall
GW, GH, T, R, RI = 90, 100, 26, 22, 6
M0, M1 = 37, 63          # the middle bar
CELL = 128
UNIT = 0.86              # texture pixels per glyph unit: digits 86 px tall
OUTLINE, HALO = 7, 12     # in glyph units


def glyph(ch):
    """The digit as an 'L' image of GW x GH units, at SS samples per unit."""
    k = SS
    im = Image.new("L", (GW * k, GH * k), 0)
    d = ImageDraw.Draw(im)

    def box(x0, y0, x1, y1, r, fill):
        d.rounded_rectangle([x0 * k, y0 * k, x1 * k - 1, y1 * k - 1], radius=r * k, fill=fill)

    def poly(points, fill):
        d.polygon([(x * k, y * k) for x, y in points], fill=fill)

    full = lambda: box(0, 0, GW, GH, R, 255)
    hole = lambda x0, y0, x1, y1: box(x0, y0, x1, y1, RI, 0)
    if ch == "0":
        full(); hole(T, T, GW - T, GH - T)
    elif ch == "1":
        box(40, 0, 40 + T, GH, 5, 255)
        poly([(42, 0), (42, T), (14, T + 12), (14, 12)], 255)
    elif ch == "2":
        full(); hole(-20, T, GW - T, M0); hole(T, M1, GW + 20, GH - T)
    elif ch == "3":
        full(); hole(-20, T, GW - T, M0); hole(-20, M1, GW - T, GH - T)
    elif ch == "4":
        full(); hole(T, -20, GW - T, M0); hole(-20, M1, GW - T, GH + 20)
    elif ch == "5":
        full(); hole(T, T, GW + 20, M0); hole(-20, M1, GW - T, GH - T)
    elif ch == "6":
        full(); hole(T, T, GW + 20, M0); hole(T, M1, GW - T, GH - T)
    elif ch == "7":
        box(0, 0, GW, GH, R, 255)
        hole(-20, T, GW - T, GH + 20)
        d.rectangle([0, T * k, GW * k, GH * k], fill=0)
        poly([(GW - T * 1.1, T - 1), (GW, T - 1), (GW * 0.6, GH), (GW * 0.6 - T * 1.15, GH)], 255)
    elif ch == "8":
        full(); hole(T, T, GW - T, M0); hole(T, M1, GW - T, GH - T)
    elif ch == "9":
        full(); hole(T, T, GW - T, M0); hole(-20, M1, GW - T, GH - T)
    return im


def cell(ch):
    """One 128 px RGBA cell: halo, black outline, white digit with a light shade."""
    big = CELL * SS
    mask = Image.new("L", (big, big), 0)
    if ch in "0123456789":
        g = glyph(ch)
        g = g.resize((round(GW * UNIT * SS), round(GH * UNIT * SS)), Image.LANCZOS)
        mask.paste(g, ((big - g.width) // 2, (big - g.height) // 2))
    m = np.asarray(mask, dtype=np.float64) / 255
    # grow the digit by OUTLINE: blur by half of it and keep what passes 2.3%, where a
    # straight edge blurred that way ends (rounds the corners like a real outline)
    grow = OUTLINE * UNIT * SS
    blurred = np.asarray(mask.filter(ImageFilter.GaussianBlur(grow / 2)), dtype=np.float64) / 255
    outline = (blurred >= 0.023).astype(np.float64)
    halo = np.asarray(Image.fromarray((outline * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(HALO * UNIT * SS * 0.6)), dtype=np.float64) / 255
    yy = np.linspace(0, 1, big)[:, None] * np.ones((1, big))
    white = 255 - 22 * yy
    rgb = np.dstack([white * m] * 3)
    alpha = np.maximum(m, np.maximum(outline, np.minimum(1, halo * 1.1)))
    rgba = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA").resize((CELL, CELL), Image.LANCZOS)


CHARS = ["0123", "4567", "89:.", " -x,"]


def font_ini():
    top = (CELL - round(GH * UNIT)) // 2
    width = round(GW * UNIT) + 6
    extra = (CELL - width) // 2
    lines = ["[common]", "Baseline=%d" % (top + round(GH * UNIT)), "Top=%d" % top,
             "LineSpacing=%d" % round(GH * UNIT * 1.2), "DrawExtraPixelsLeft=%d" % extra,
             "DrawExtraPixelsRight=%d" % extra, "AdvanceExtraPixels=0", "", "[numbers]"]
    lines += ["Line %d=%s" % (i, row) for i, row in enumerate(CHARS)]
    lines.append("")
    for i, ch in enumerate("".join(CHARS)):
        lines.append("%d=%d" % (i, width if ch in "0123456789" else width // 3))
    return "\n".join(lines) + "\n"


def main():
    theme = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    (frame_rgb, frame_a), (smoke_rgb, smoke_a), save = frame_images()
    save(frame_rgb, frame_a, os.path.join(theme, "Graphics", "UI", "Timer frame.png"))
    save(smoke_rgb, smoke_a, os.path.join(theme, "Graphics", "UI", "Timer smoke.png"))

    sheet = Image.new("RGBA", (CELL * 4, CELL * 4), (0, 0, 0, 0))
    for row, chars in enumerate(CHARS):
        for col, ch in enumerate(chars):
            sheet.paste(cell(ch), (col * CELL, row * CELL))
    sheet.save(os.path.join(theme, "Fonts", "Timer digits [numbers] 4x4.png"))
    with open(os.path.join(theme, "Fonts", "Timer digits.ini"), "w", newline="\n") as f:
        f.write(font_ini())
    print("timer written to", theme)


if __name__ == "__main__":
    main()
