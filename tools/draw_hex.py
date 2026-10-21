"""Draws the small PNGs the Phoenix-style select screens need (Graphics/Select/).

Run from anywhere: python -I tools/draw_hex.py
"""
import math
import os

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Graphics", "Select")


def hexagon(size, inset=0):
    """Vertices of a regular hexagon (points up/down) inscribed in a size x size box."""
    cx = cy = size / 2
    r = size / 2 - inset
    return [(cx + r * math.cos(math.radians(60 * i - 90)), cy + r * math.sin(math.radians(60 * i - 90))) for i in range(6)]


def hex_frame(size=512, border=12):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon(hexagon(size, 2), fill=(255, 255, 255, 255))
    d.polygon(hexagon(size, 2 + border), fill=(0, 0, 0, 0))
    return img


def hex_mask(size=512):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(img).polygon(hexagon(size, 2), fill=(255, 255, 255, 255))
    return img


def rainbow(w=1024, h=64):
    img = Image.new("RGBA", (w, h))
    px = img.load()
    for x in range(w):
        hue = x / w
        r, g, b = _hsv(hue, 1.0, 1.0)
        for y in range(h):
            px[x, y] = (r, g, b, 255)
    return img


def _hsv(h, s, v):
    i = int(h * 6) % 6
    f = h * 6 - int(h * 6)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    r, g, b = [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)][i]
    return int(r * 255), int(g * 255), int(b * 255)


def gradient_bg(size=512, inner=(0x13, 0x20, 0x3a), outer=(0x05, 0x07, 0x0d)):
    img = Image.new("RGBA", (size, size))
    px = img.load()
    cx, cy = size / 2, size * 0.3
    maxd = math.hypot(size, size)
    for y in range(size):
        for x in range(size):
            k = min(1.0, math.hypot(x - cx, y - cy) / (maxd * 0.6))
            px[x, y] = tuple(int(inner[c] + (outer[c] - inner[c]) * k) for c in range(3)) + (255,)
    return img


def grid(size=64, alpha=10):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.line([(0, 0), (size - 1, 0)], fill=(255, 255, 255, alpha))
    d.line([(0, 0), (0, size - 1)], fill=(255, 255, 255, alpha))
    return img


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, img in [
        ("hex_frame.png", hex_frame()),
        ("hex_mask.png", hex_mask()),
        ("gradient_bg.png", gradient_bg()),
    ]:
        img.save(os.path.join(OUT, name))
        print("wrote", name, img.size)
