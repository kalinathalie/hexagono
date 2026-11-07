#!/usr/bin/env python3
"""Draws the gray glossy orb of the top HUD's player card (Graphics/UI/Orb.png), the
theme's own art after the rank orb Phoenix 2 shows for a player without a rank: a
metallic gray sphere lit from the upper left, with a broad soft highlight and a darker rim.

Usage: python tools/make_orb.py [OUT.png] [--size 128]
"""
import argparse
import os

import numpy as np
from PIL import Image


def orb(size):
    """RGBA uint8 array of the orb, size x size, anti-aliased edge."""
    r = size / 2.0
    y, x = np.mgrid[0:size, 0:size].astype(np.float64)
    nx, ny = (x + 0.5 - r) / (r - 1), (y + 0.5 - r) / (r - 1)
    d2 = nx * nx + ny * ny
    nz = np.sqrt(np.clip(1.0 - d2, 0.0, 1.0))
    light = np.array([-0.45, -0.55, 0.70])
    light /= np.linalg.norm(light)
    diffuse = np.clip(nx * light[0] + ny * light[1] + nz * light[2], 0.0, 1.0)
    # specular: reflection of the light about the normal, seen from the front
    rz = 2 * diffuse * nz - light[2]
    spec = np.clip(rz, 0.0, 1.0) ** 6
    rim = np.clip((np.sqrt(d2) - 0.75) / 0.25, 0.0, 1.0)
    shade = 0.30 + 0.62 * diffuse - 0.15 * rim
    gray = np.clip(135.0 * shade + 255.0 * 0.45 * spec, 0.0, 255.0)
    rgb = np.dstack([gray * 0.97, gray * 0.99, gray * 1.03])
    alpha = np.clip((1.0 - np.sqrt(d2)) * (r - 1), 0.0, 1.0) * 255.0
    return np.dstack([np.clip(rgb, 0, 255), alpha]).astype(np.uint8)


def main():
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("out", nargs="?", default=os.path.join(here, "Graphics", "UI", "Orb.png"))
    ap.add_argument("--size", type=int, default=128)
    a = ap.parse_args()
    Image.fromarray(orb(a.size), "RGBA").save(a.out)
    print("orb written to", a.out)


if __name__ == "__main__":
    main()
