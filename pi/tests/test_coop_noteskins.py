"""Tests for the co-op noteskins pi/assets/coop_noteskins.py builds from every Pump noteskin.
Run: python pi/tests/test_coop_noteskins.py"""
import os
import sys
import tempfile

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets"))
import coop_noteskins as cn  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


# names
check(cn.wrapper_name("nx2") == "nx2-coop" and cn.variant_name("nx2", 3) == "nx2-coop3", "wrapper and variant names")
for name in ("nx2-coop", "nx2-coop1", "fiesta_2-coop5", "hexagono-coop"):
    check(cn.is_generated(name), "%s is generated" % name)
for name in ("nx2", "coop", "double_per_p1", "SanityP1", "my-cooper"):
    check(not cn.is_generated(name), "%s is a real noteskin" % name)
check(len(cn.COLORS) == 5 and cn.COLORS[0][0] > 200 and cn.COLORS[1][2] > 200, "5 player colors, P1 red, P2 blue")

# colorize: colored pixels take the player's hue, greys and alpha stay
px = np.array([[[40, 120, 250, 255], [128, 128, 128, 255], [255, 255, 255, 200], [0, 0, 0, 0]]], dtype=np.uint8)
out = cn.colorize(px, (235, 45, 45))
check(out.shape == px.shape and out.dtype == np.uint8, "colorize keeps the shape")
r, g, b, a = out[0, 0]
check(r > g + 60 and r > b + 60, "a blue fill turns red for P1 (got %s)" % list(out[0, 0]))
check(abs(int(out[0, 1, 0]) - int(out[0, 1, 1])) < 4 and abs(int(out[0, 1, 1]) - int(out[0, 1, 2])) < 4, "grey stays grey")
check(list(out[0, 2]) == [255, 255, 255, 200], "white stays white, alpha kept")
check(out[0, 3, 3] == 0, "transparent stays transparent")

# metrics
check(cn.variant_metrics("[Global]\nFallbackNoteSkin=xs_default\n\n[NoteDisplay]\nX=1\n", 2, {"xs_default"})
      == "[Global]\nFallbackNoteSkin=xs_default-coop2\n\n[NoteDisplay]\nX=1\n", "a variant falls back to its fallback's variant")
check(cn.variant_metrics("[Global]\nFallbackNoteSkin=common\n", 2, {"xs_default"}) == "[Global]\nFallbackNoteSkin=common\n",
      "a fallback without variants stays")
check(cn.variant_metrics("[Global]\r\nFallbackNoteSkin=xs_default\r\n", 4, {"xs_default"}) == "[Global]\r\nFallbackNoteSkin=xs_default-coop4\r\n",
      "Windows line ends kept")
check(cn.wrapper_metrics("nx2") == "[Global]\nFallbackNoteSkin=nx2\n\n[NoteDisplay]\nNumPlayers=5\n", "wrapper metrics")
check(cn.wrapper_script("-- body\n", "nx2") == 'local Base = "nx2"\n-- body\n', "wrapper script names its base")


def make_skin(root, name, fallback=None, color=(40, 120, 250, 255)):
    d = os.path.join(root, name)
    os.makedirs(d)
    Image.new("RGBA", (4, 2), color).save(os.path.join(d, "DownLeft Tap Note 2x1.png"))
    with open(os.path.join(d, "NoteSkin.lua"), "w") as f:
        f.write("return {} -- %s" % name)
    with open(os.path.join(d, "metrics.ini"), "w") as f:
        f.write("[Global]\nFallbackNoteSkin=%s\n" % (fallback or ""))


with tempfile.TemporaryDirectory() as root:
    make_skin(root, "nx2")
    make_skin(root, "nx2-dog", fallback="nx2")
    os.makedirs(os.path.join(root, "hexagono-coop"))           # the old single co-op skin
    os.makedirs(os.path.join(root, "gone-coop3"))              # a copy whose noteskin was removed
    template = os.path.join(root, "template.lua")
    with open(template, "w") as f:
        f.write("-- wrapper\n")
    built, skipped = cn.build(root, template)
    names = sorted(os.listdir(root))
    check(built == ["nx2", "nx2-dog"] and skipped == [], "both noteskins built")
    check("hexagono-coop" not in names and "gone-coop3" not in names, "old and stale copies removed")
    for n in range(1, 6):
        check("nx2-coop%d" % n in names, "nx2-coop%d exists" % n)
    check("nx2-coop" in names and "nx2-dog-coop" in names, "wrappers exist")
    im = Image.open(os.path.join(root, "nx2-coop2", "DownLeft Tap Note 2x1.png")).convert("RGBA")
    rr, gg, bb, aa = im.getpixel((0, 0))
    check(bb > rr + 40, "P2 copy is blue")
    im = Image.open(os.path.join(root, "nx2-coop1", "DownLeft Tap Note 2x1.png")).convert("RGBA")
    rr, gg, bb, aa = im.getpixel((0, 0))
    check(rr > bb + 40, "P1 copy is red")
    with open(os.path.join(root, "nx2-coop1", "NoteSkin.lua")) as f:
        check(f.read() == "return {} -- nx2", "the copy keeps the noteskin's own script")
    with open(os.path.join(root, "nx2-dog-coop3", "metrics.ini")) as f:
        check("FallbackNoteSkin=nx2-coop3" in f.read(), "nx2-dog's P3 copy falls back to nx2's P3 copy")
    with open(os.path.join(root, "nx2-coop", "NoteSkin.lua")) as f:
        check(f.read() == 'local Base = "nx2"\n-- wrapper\n', "wrapper script")
    with open(os.path.join(root, "nx2-coop", "metrics.ini")) as f:
        check("NumPlayers=5" in f.read(), "wrapper declares 5 players")
    built, skipped = cn.build(root, template)
    check(built == [] and skipped == ["nx2", "nx2-dog"], "a second run skips unchanged noteskins")
    with open(os.path.join(root, "nx2", "NoteSkin.lua"), "a") as f:
        f.write("\n-- changed")
    built, skipped = cn.build(root, template)
    check(built == ["nx2"], "a changed noteskin is built again")

print("all passed" if failures == 0 else "%d failed" % failures)
sys.exit(1 if failures else 0)
