#!/usr/bin/env python3
"""Cuts the 32 Pump It Up Phoenix 2 grade icons out of the "SSS+~F Stage Pass & Stage
Break Off Result Grade Sound" video on YouTube (1080p60), into OUT_DIR (the theme reads
Graphics/Phoenix/Evaluation/Grades and falls back to phyrebird's Phoenix 1 style icons
one folder up):

  R_<grade>.png  normal play (SSS+ .. F), B_<grade>.png  broken play (cracked silver),
                 520x296, at the video's 1080p scale, the grade center in the middle
                 (the result screen draws them at 2/3: one texture pixel per screen pixel)
  info.ini       [Grades] Count=32 (written last: assets.sh skips this step when present)

Every grade sits still over the song's still background for a few seconds. For each
one: the frame where it appears, the mean of the frames just before it (the
background) and the mean of the frames 1.5-2 s after (the grade over it), then a
difference matte gives its color and transparency.

Needs ffmpeg, numpy and Pillow, and, to download, yt-dlp with node. Usage:
  python3 grades.py OUT_DIR [--source VIDEO] [--work DIR] [--yt-dlp CMD]
"""
import argparse
import os
import subprocess
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import title  # noqa: E402  (same folder: download)

URL = "https://youtu.be/d4KZawyd7FE"
GRADES = ["SSS+", "SSS", "SS+", "SS", "S+", "S", "AAA+", "AAA", "AA+", "AA", "A+", "A", "B", "C", "D", "F"]
CENTER_X = {"P1": 360, "P2": 1560}   # grade center on the 1080p video (theme 240 and 1040, y 428)
CENTER_Y = 642
WIDTH = 520                          # the "+" of SSS+ reaches 250 px right of the center
UP, DOWN = 130, 148                  # rows kept above and below the center: the "+score" text
                                     # ends at row ~505 and the plate starts at ~797 (even sizes:
                                     # ffmpeg's crop rounds odd ones)
FPS = 60
# (icon, side, second): the first whole second the grade shows on that side (1 fps scan)
SHOTS = [
    ("R_SSS+", "P2", 3), ("R_SSS", "P1", 3), ("R_SS+", "P1", 23), ("R_SS", "P1", 34),
    ("R_S+", "P1", 44), ("R_S", "P1", 55), ("R_AAA+", "P1", 65), ("R_AAA", "P1", 75),
    ("R_AA+", "P1", 84), ("R_AA", "P1", 95), ("R_A+", "P1", 103), ("R_A", "P1", 114),
    ("R_B", "P1", 124), ("R_C", "P1", 133), ("R_D", "P1", 143), ("R_F", "P2", 155),
    ("B_SSS+", "P2", 165), ("B_SSS", "P2", 173), ("B_SS+", "P2", 181), ("B_SS", "P2", 188),
    ("B_S+", "P2", 196), ("B_S", "P2", 203), ("B_AAA+", "P2", 211), ("B_AAA", "P2", 219),
    ("B_AA+", "P1", 227), ("B_AA", "P2", 235), ("B_A+", "P1", 242), ("B_A", "P1", 250),
    ("B_B", "P2", 257), ("B_C", "P1", 257), ("B_D", "P2", 270), ("B_F", "P2", 278),
]
LEAD = 1.3            # seconds read before the shot second, to see the grade appear
LAG = 0.8             # and after it: a 1 fps scan sees a grade up to ~0.6 s before it lands
APPEAR = 6.0          # mean difference (0-255) over the grade rows that means it appeared
BG_FRAMES = (21, 3)   # background: frames 21 to 3 before the grade (the "+score" text shows 30 before)
FG_FRAMES = (90, 120)  # grade over it: frames 90 to 120 after (1.5-2 s, after the entrance)


def first_change(diffs, threshold):
    """Index of the first value above threshold, or None."""
    for i, d in enumerate(diffs):
        if d > threshold:
            return i
    return None


def region_diffs(frames, top, bottom):
    """Mean absolute difference of each frame to the first, over rows top..bottom."""
    part = frames[:, top:bottom].astype(np.float64)
    return np.abs(part - part[0]).mean(axis=(1, 2, 3))


def matte(bg, fg, lo=10.0, hi=60.0):
    """RGBA uint8 from a background and the same background with something over it:
    alpha grows from 0 to 1 as the largest channel difference goes from lo to hi, and
    the color is solved from fg = alpha * color + (1 - alpha) * bg."""
    a = np.clip((np.abs(fg - bg).max(axis=2) - lo) / (hi - lo), 0.0, 1.0)
    a3 = a[..., None]
    color = np.where(a3 > 0, (fg - (1.0 - a3) * bg) / np.maximum(a3, 1e-3), 0.0)
    return np.dstack([np.clip(np.round(color), 0, 255), np.round(a * 255.0)]).astype(np.uint8)


def clean(rgba, min_pixels=200, bottom=8, faint=16):
    """A copy without what is not the grade: pixels fainter than faint, the last bottom
    rows (the plate's top edge) and blobs (8-connected, alpha >= faint) smaller than
    min_pixels (compression specks)."""
    out = rgba.copy()
    alpha = out[..., 3]
    alpha[alpha < faint] = 0
    if bottom:
        alpha[-bottom:] = 0
    h, w = alpha.shape
    seen = np.zeros((h, w), bool)
    for y0, x0 in zip(*np.nonzero(alpha)):
        if seen[y0, x0]:
            continue
        seen[y0, x0] = True
        blob, stack = [], [(y0, x0)]
        while stack:
            y, x = stack.pop()
            blob.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx] and alpha[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        if len(blob) < min_pixels:
            ys, xs = zip(*blob)
            alpha[list(ys), list(xs)] = 0
    return out


def centered(crop, up, down):
    """The crop (up rows above the center, down below) padded with transparent rows so
    the center is the middle of the image."""
    half = max(up, down)
    out = np.zeros((2 * half,) + crop.shape[1:], crop.dtype)
    out[half - up:half + down] = crop
    return out


def grade_ini(count):
    return "[Grades]\nSource=%s\nCount=%d\n" % (URL, count)


def read_frames(src, start, seconds, side):
    x = CENTER_X[side] - WIDTH // 2
    h = UP + DOWN
    raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", "%.3f" % start, "-t", "%.3f" % seconds, "-i", src,
                          "-vf", "crop=%d:%d:%d:%d" % (WIDTH, h, x, CENTER_Y - UP),
                          "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(-1, h, WIDTH, 3)


def cut(src, side, second):
    start = second - LEAD
    search = int((LEAD + LAG) * FPS)
    frames = read_frames(src, start, (search + FG_FRAMES[1] + 10) / FPS, side)
    # the grade rows only: the "+score" text above appears half a second earlier
    g = first_change(region_diffs(frames[:search], UP - 100, UP + 100), APPEAR)
    if g is None or g < BG_FRAMES[0] or g + FG_FRAMES[1] > len(frames):
        raise RuntimeError("grade at %d s (%s) not found" % (second, side))
    bg = frames[g - BG_FRAMES[0]:g - BG_FRAMES[1]].astype(np.float64).mean(axis=0)
    fg = frames[g + FG_FRAMES[0]:g + FG_FRAMES[1]].astype(np.float64).mean(axis=0)
    return Image.fromarray(centered(clean(matte(bg, fg)), UP, DOWN), "RGBA"), start + g / FPS


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("out")
    ap.add_argument("--source", help="the downloaded YouTube video (skips the download)")
    ap.add_argument("--work", default=os.path.join(os.path.expanduser("~"), ".cache", "hexagono-assets", "grades"))
    ap.add_argument("--yt-dlp", default="yt-dlp", help="yt-dlp command")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    os.makedirs(a.work, exist_ok=True)
    src = a.source or title.download(a.work, a.yt_dlp.split(), URL)
    size = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                           "stream=width,height,r_frame_rate", "-of", "csv=p=0", src],
                          capture_output=True, text=True, check=True).stdout.strip()
    if size != "1920,1080,60/1":
        sys.exit("unexpected source video (%s): the cut points are for the 1080p60 upload" % size)
    info = os.path.join(a.out, "info.ini")
    if os.path.exists(info):
        os.remove(info)
    for name, side, second in SHOTS:
        image, at = cut(src, side, second)
        image.save(os.path.join(a.out, name + ".png"))
        print("%-7s %s %.2f s" % (name, side, at))
    with open(info, "w", newline="\n") as f:
        f.write(grade_ini(len(SHOTS)))
    print("grades written to", a.out)


if __name__ == "__main__":
    main()
