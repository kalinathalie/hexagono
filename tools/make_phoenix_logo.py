#!/usr/bin/env python3
"""The Pump It Up Phoenix 2 logo for the title screen (Graphics/Phoenix/Logo/PhoenixLogo.png),
shown when there is no title video.

The source is the logo on a white background (by default the image the theme was made
with). The white around the dark outline becomes transparent (flood fill from the
border, then color-to-alpha against white, so the glow keeps its soft edge); the
inside of the letters stays opaque. The edge is then strengthened a little
(alpha ** 0.7) because the title screen draws the logo with an additive glow.

Usage:  python3 tools/make_phoenix_logo.py [--src IMAGE_OR_URL] [--out PNG]
"""
import argparse
import io
import os
import urllib.request

import numpy as np

from PIL import Image, ImageDraw, ImageFilter

SOURCE = ("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQXj_L6sqUMe34Otm3f0IbM6kAhWZfe_"
          "Qarm051IRt6EWgpwTTxvyb99EGj&s=10")


def load(src):
    if src.startswith("http"):
        req = urllib.request.Request(src, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=60) as r:
            return Image.open(io.BytesIO(r.read())).convert("RGB")
    return Image.open(src).convert("RGB")


def cut_out(im):
    pad = 4
    big = Image.new("RGB", (im.width + 2 * pad, im.height + 2 * pad), (255, 255, 255))
    big.paste(im, (pad, pad))
    a = np.asarray(big).astype(float)
    lum = a @ np.array([0.299, 0.587, 0.114])
    # the outside can flow through anything that is not the dark outline
    passable = Image.fromarray(((lum > 95) * 255).astype(np.uint8), "L").copy()
    ImageDraw.floodfill(passable, (0, 0), 128, thresh=0)
    outside = np.asarray(passable) == 128
    alpha = np.where(outside, np.max((255 - a) / 255, axis=2), 1.0)
    alpha = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(0.6))).astype(float) / 255
    rgb = a.copy()
    soft = (alpha > 0.01) & outside
    rgb[soft] = np.clip(255 - (255 - a[soft]) / alpha[soft][:, None], 0, 255)
    logo = Image.fromarray(np.dstack([rgb, alpha * 255]).astype(np.uint8), "RGBA")
    return logo.crop(logo.getchannel("A").point(lambda v: 255 if v > 6 else 0).getbbox())


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--src", default=SOURCE)
    ap.add_argument("--out", default=os.path.join(here, "Graphics", "Phoenix", "Logo", "PhoenixLogo.png"))
    a = ap.parse_args()
    logo = cut_out(load(a.src))
    r, g, b, alpha = logo.split()
    alpha = Image.fromarray((255 * (np.asarray(alpha).astype(float) / 255) ** 0.7).astype(np.uint8), "L")
    os.makedirs(os.path.dirname(a.out), exist_ok=True)
    Image.merge("RGBA", (r, g, b, alpha)).save(a.out)
    print("logo written to", a.out, logo.size)


if __name__ == "__main__":
    main()
