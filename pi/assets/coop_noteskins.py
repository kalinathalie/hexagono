#!/usr/bin/env python3
"""Makes every Pump noteskin co-op ready, so on a co-op chart each player's notes have
their own color whatever noteskin the player chose (P1 red, P2 blue, P3 yellow, P4 green,
P5 pink, as in Phoenix). For each noteskin X in NoteSkins/pump:

  X-coop1 .. X-coop5   full copies of X with every image recolored to one player's color
                       (shape, outlines and highlights kept), X's own scripts, and the
                       fallback pointing to the fallback's copy of the same color
  X-coop               the noteskin the theme switches to on co-op charts: its metrics say
                       NumPlayers=5, so OutFox asks it for player n's notes as "P<n> ...";
                       its script (pi/config/noteskins/coop/NoteSkin.lua) loads each
                       player's notes from X-coop<n>, and receptors, explosions and mines
                       from X itself

A noteskin whose files did not change since the last run is skipped; copies of a removed
noteskin are deleted. The art stays the noteskins' own, so this runs on the machine and
never goes to the repository. Needs Pillow and numpy.
Usage: python3 coop_noteskins.py NOTESKINS_PUMP_DIR
"""
import hashlib
import os
import re
import shutil
import sys

import numpy as np
from PIL import Image

VERSION = 1   # bump when the recolor changes, to rebuild everything
PLAYERS = 5
COLORS = [(235, 45, 45), (45, 140, 255), (255, 205, 35), (45, 225, 70), (235, 60, 210)]
LEGACY = "hexagono-coop"
SIGNATURE = ".coop-signature"
HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HERE, "..", "config", "noteskins", "coop", "NoteSkin.lua")
GENERATED = re.compile(r"-coop\d?$")


def wrapper_name(base):
    return base + "-coop"


def variant_name(base, n):
    return "%s-coop%d" % (base, n)


def is_generated(name):
    return name == LEGACY or GENERATED.search(name) is not None


def colorize(rgba, rgb):
    """The image (H x W x 4 uint8) in one color: its colored pixels follow a black - color -
    white ramp by brightness, centered so the typical fill becomes the color itself; greys,
    white and black stay as they are; alpha is kept."""
    a = rgba.astype(np.float64) / 255
    lum = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
    hi_c, lo_c = a[..., :3].max(axis=2), a[..., :3].min(axis=2)
    sat = np.where(hi_c > 0, (hi_c - lo_c) / np.maximum(hi_c, 1e-6), 0)
    colored = (a[..., 3] > 0.5) & (sat > 0.25)
    mid = float(np.median(lum[colored])) if colored.any() else 0.5
    mid = min(0.7, max(0.3, mid))
    c = np.array(rgb, dtype=np.float64) / 255
    below = np.clip(lum / mid, 0, 1)[..., None] * c
    above = c + np.clip((lum - mid) / (1 - mid), 0, 1)[..., None] * (1 - c)
    ramp = np.where((lum <= mid)[..., None], below, above)
    k = np.clip(sat * 1.6, 0, 1)[..., None]
    rgb_out = k * ramp + (1 - k) * lum[..., None]
    out = np.dstack([rgb_out, a[..., 3:4]])
    return np.rint(np.clip(out, 0, 1) * 255).astype(np.uint8)


def variant_metrics(text, n, bases):
    def swap(m):
        value = m.group(2).strip()
        return m.group(1) + (variant_name(value, n) if value in bases else m.group(2))
    return re.sub(r"(FallbackNoteSkin=)([^\r\n]*)", swap, text)


def wrapper_metrics(base):
    return "[Global]\nFallbackNoteSkin=%s\n\n[NoteDisplay]\nNumPlayers=%d\n" % (base, PLAYERS)


def wrapper_script(template, base):
    return 'local Base = "%s"\n%s' % (base, template)


def signature(folder, template):
    h = hashlib.sha1(("%d\n%s" % (VERSION, template)).encode())
    for root, _, files in sorted(os.walk(folder)):
        for f in sorted(files):
            p = os.path.join(root, f)
            st = os.stat(p)
            h.update(("%s|%d|%d\n" % (os.path.relpath(p, folder), st.st_size, int(st.st_mtime))).encode())
    return h.hexdigest()


def write_text(path, text):
    with open(path, "w", newline="") as f:
        f.write(text)


def build_variant(src, dest, n, bases):
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    for root, _, files in os.walk(src):
        out = os.path.join(dest, os.path.relpath(root, src))
        os.makedirs(out, exist_ok=True)
        for f in files:
            s, d = os.path.join(root, f), os.path.join(out, f)
            if f.lower().endswith(".png"):
                try:
                    with Image.open(s) as im:
                        rgba = np.asarray(im.convert("RGBA"))
                    Image.fromarray(colorize(rgba, COLORS[n - 1]), "RGBA").save(d)
                    continue
                except OSError:
                    pass   # not readable as an image: copied as it is
            if f.lower() == "metrics.ini" and root == src:
                with open(s, newline="", errors="replace") as fh:
                    write_text(d, variant_metrics(fh.read(), n, bases))
                continue
            shutil.copyfile(s, d)


def build(pump, template_path=TEMPLATE):
    """Builds what changed; returns (built, skipped) base noteskin names."""
    with open(template_path, newline="") as f:
        template = f.read()
    names = sorted(n for n in os.listdir(pump) if os.path.isdir(os.path.join(pump, n)))
    bases = [n for n in names if not is_generated(n)]
    for n in names:
        if is_generated(n) and (n == LEGACY or GENERATED.sub("", n) not in bases):
            shutil.rmtree(os.path.join(pump, n))
    built, skipped = [], []
    for base in bases:
        src = os.path.join(pump, base)
        wrapper = os.path.join(pump, wrapper_name(base))
        sig = signature(src, template)
        sig_file = os.path.join(wrapper, SIGNATURE)
        if os.path.isfile(sig_file):
            with open(sig_file) as f:
                if f.read() == sig:
                    skipped.append(base)
                    continue
        for n in range(1, PLAYERS + 1):
            build_variant(src, os.path.join(pump, variant_name(base, n)), n, set(bases))
        if os.path.isdir(wrapper):
            shutil.rmtree(wrapper)
        os.makedirs(wrapper)
        write_text(os.path.join(wrapper, "NoteSkin.lua"), wrapper_script(template, base))
        write_text(os.path.join(wrapper, "metrics.ini"), wrapper_metrics(base))
        write_text(sig_file, sig)   # last: an interrupted run builds this noteskin again
        built.append(base)
    return built, skipped


def main():
    built, skipped = build(sys.argv[1])
    print("co-op noteskins: %d built, %d up to date" % (len(built), len(skipped)))


if __name__ == "__main__":
    main()
