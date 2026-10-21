#!/usr/bin/env python3
"""Sharp 400x300 thumbnails for the song select wheel.

The wheel shows song banners through OutFox's image cache, which keeps them at
128-160 px wide, and most PIU banners are only 160x120 on disk. The song's
background is usually the same title art at 640x480 or more, so each thumbnail
is cut from the background (center 4:3 crop) when it shows the same picture as
the banner; otherwise the banner itself is resized. Output goes to the theme's
Thumbs folder (Thumbs/<pack>/<song>.jpg), which the wheel loads by song folder.

Usage (on the machine that runs OutFox):
    python3 tools/make_thumbs.py                      # ~/.project-outfox/Songs -> ./Thumbs
    python3 tools/make_thumbs.py --songs DIR --out DIR --force
Only songs whose thumbnail is missing or older than its source are redone.
"""
import argparse
import os
import re
import sys

from PIL import Image, ImageOps

IMAGE_EXT = (".png", ".jpg", ".jpeg", ".bmp", ".gif")
W, H = 400, 300


def tag_value(text, tag):
    m = re.search(r"#" + tag + r"\s*:\s*([^;]*);", text, re.IGNORECASE)
    return m.group(1).strip() if m else ""


def find_ci(folder, name, files):
    """Case-insensitive file lookup inside the song folder (Linux is case sensitive)."""
    if not name:
        return None
    base = os.path.basename(name.replace("\\", "/")).lower()
    for f in files:
        if f.lower() == base:
            return os.path.join(folder, f)
    return None


def chart_text(folder, files):
    for ext in (".ssc", ".sm"):
        for f in files:
            if f.lower().endswith(ext):
                try:
                    with open(os.path.join(folder, f), encoding="utf-8", errors="replace") as h:
                        return h.read(20000)
                except OSError:
                    pass
    return ""


def is_banner_name(f):
    n = f.lower()
    return n.endswith(("_b.png", "_b.jpg", "-bn.png", " bn.png", "bn.png", "-bn.jpg")) or "banner" in n


def sources(folder):
    files = os.listdir(folder)
    text = chart_text(folder, files)
    banner = find_ci(folder, tag_value(text, "BANNER"), files)
    if not banner:
        banner = next((os.path.join(folder, f) for f in files if is_banner_name(f) and f.lower().endswith(IMAGE_EXT)), None)
    bg = find_ci(folder, tag_value(text, "BACKGROUND"), files)
    if bg and not bg.lower().endswith(IMAGE_EXT):
        bg = None
    if not bg:
        # the largest other image in the folder (title cards are named after the song)
        best, best_px = None, 0
        for f in files:
            p = os.path.join(folder, f)
            if not f.lower().endswith(IMAGE_EXT) or is_banner_name(f) or p == banner:
                continue
            try:
                with Image.open(p) as im:
                    px = im.size[0] * im.size[1]
            except Exception:
                continue
            if px > best_px:
                best, best_px = p, px
        bg = best
    return banner, bg


def cover(im):
    im = ImageOps.exif_transpose(im).convert("RGB")
    return ImageOps.fit(im, (W, H), Image.LANCZOS, centering=(0.5, 0.5))


def signature(im):
    return list(im.convert("L").resize((16, 12), Image.BILINEAR).getdata())


def same_picture(a, b):
    sa, sb = signature(a), signature(b)
    return sum(abs(x - y) for x, y in zip(sa, sb)) / len(sa) < 20


def make(folder, out, force):
    banner, bg = sources(folder)
    newest = max((os.path.getmtime(p) for p in (banner, bg) if p), default=0)
    if newest == 0:
        return "none"
    if not force and os.path.exists(out) and os.path.getmtime(out) >= newest:
        return "kept"
    pick, kind = None, None
    try:
        b = None
        if banner:
            with Image.open(banner) as raw:
                b = cover(raw)
        if bg:
            with Image.open(bg) as raw:
                big = raw.size[0] >= W
                g = cover(raw) if big else None
            if g is not None and (b is None or same_picture(g, b)):
                pick, kind = g, "background"
        if pick is None and b is not None:
            pick, kind = b, "banner"
    except Exception as e:
        print("skip", folder, e, file=sys.stderr)
        return "error"
    if pick is None:
        return "none"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    pick.save(out, "JPEG", quality=90, optimize=True)
    return kind


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--songs", action="append", help="songs folder (repeatable), default ~/.project-outfox/Songs")
    ap.add_argument("--out", default=os.path.join(here, "Thumbs"), help="output folder, default <theme>/Thumbs")
    ap.add_argument("--force", action="store_true", help="redo every thumbnail")
    a = ap.parse_args()
    roots = a.songs or [os.path.expanduser("~/.project-outfox/Songs")]
    counts = {}
    for root in roots:
        for pack in sorted(os.listdir(root)):
            pdir = os.path.join(root, pack)
            if not os.path.isdir(pdir):
                continue
            for song in sorted(os.listdir(pdir)):
                sdir = os.path.join(pdir, song)
                if not os.path.isdir(sdir):
                    continue
                r = make(sdir, os.path.join(a.out, pack, song + ".jpg"), a.force)
                counts[r] = counts.get(r, 0) + 1
    print(" ".join("%s=%d" % kv for kv in sorted(counts.items())))


if __name__ == "__main__":
    main()
