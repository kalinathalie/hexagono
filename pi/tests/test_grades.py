"""Tests for the pure parts of pi/assets/grades.py (no video, no network).
Run: python pi/tests/test_grades.py"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets"))
import grades  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


# the shot list covers every grade once, normal and broken
names = [s[0] for s in grades.SHOTS]
want = {p + "_" + g for p in ("R", "B") for g in grades.GRADES}
check(len(names) == 32 and set(names) == want, "32 shots, one per R_/B_ grade")
check(all(side in grades.CENTER_X for _, side, _ in grades.SHOTS), "every shot is on P1 or P2")
check(all(isinstance(n, int) and 1 <= n <= 280 for _, _, n in grades.SHOTS), "shot seconds inside the video")

# first_change: the first frame whose difference passes the threshold
check(grades.first_change([0.1, 0.3, 0.2, 7.5, 30.0], 6.0) == 3, "first change at index 3")
check(grades.first_change([0.1, 0.3, 0.2], 6.0) is None, "no change: None")
check(grades.first_change([6.0, 9.0], 6.0) == 1, "the threshold itself is not a change")

# region_diffs: mean absolute difference of each frame to the first one, over some rows
frames = np.zeros((3, 4, 2, 3), np.uint8)
frames[1, 2:, :, :] = 40          # rows 2-3 change by 40
frames[2, :2, :, :] = 90          # rows 0-1 change by 90
d = grades.region_diffs(frames, 2, 4)
check(len(d) == 3 and d[0] == 0 and abs(d[1] - 40) < 1e-9 and d[2] == 0, "diffs over rows 2-3 only: %s" % list(d))

# matte: alpha and color recovered from a background and a composite
bg = np.zeros((1, 4, 3))
bg[0, :] = (40, 60, 80)
fg = bg.copy()
fg[0, 1] = (250, 250, 250)                          # opaque white
fg[0, 2] = (75, 60, 80)                             # a difference of 35: halfway up the 10-60 ramp
out = grades.matte(bg, fg, lo=10.0, hi=60.0)
check(out.shape == (1, 4, 4) and out.dtype == np.uint8, "matte gives uint8 RGBA")
check(out[0, 0, 3] == 0, "unchanged pixel is transparent")
check(out[0, 1, 3] == 255 and tuple(out[0, 1, :3]) == (250, 250, 250), "opaque pixel keeps its color")
check(out[0, 2, 3] in (127, 128) and tuple(out[0, 2, :3]) == (110, 60, 80),
      "small difference: alpha 0.5 and the color solved from it (%s)" % (tuple(out[0, 2]),))
check(out[0, 3, 3] == 0, "second unchanged pixel is transparent")

# centered: pads the crop so the grade center is the middle row
crop = np.zeros((5, 2, 4), np.uint8)
crop[0] = 9                       # first row of the crop (2 rows above the center)
c = grades.centered(crop, up=2, down=3)
check(c.shape == (6, 2, 4), "padded to 2 * max(up, down) rows: %s" % (c.shape,))
check(c[1, 0, 0] == 9 and c[0, 0, 3] == 0, "the crop sits 1 row lower, the top row is transparent")

# clean: drops the faint haze, small specks and the bottom rows (the plate's edge)
img = np.zeros((40, 40, 4), np.uint8)
img[5:25, 5:25] = (200, 200, 200, 255)     # the grade: a 20x20 block (400 px)
img[30:33, 30:33] = (90, 90, 90, 200)      # a 3x3 speck
img[2, 35] = (50, 50, 50, 10)              # faint haze
img[38:40, :] = (255, 120, 0, 255)         # the plate's top edge in the last 2 rows
c = grades.clean(img, min_pixels=50, bottom=4, faint=16)
check(c[10, 10, 3] == 255 and tuple(c[10, 10, :3]) == (200, 200, 200), "the grade block stays")
check(c[31, 31, 3] == 0, "a small speck goes")
check(c[2, 35, 3] == 0, "faint haze goes")
check(c[39, 20, 3] == 0 and c[38, 0, 3] == 0, "the bottom rows go")
check(img[31, 31, 3] == 200, "the input is not changed")

# grade_ini marks the folder complete
check(grades.grade_ini(32) == "[Grades]\nSource=https://youtu.be/d4KZawyd7FE\nCount=32\n", "info.ini text")

print("all passed" if failures == 0 else "%d failed" % failures, failures)
sys.exit(1 if failures else 0)
