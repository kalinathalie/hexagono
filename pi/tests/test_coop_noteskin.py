"""Tests for the co-op noteskin pi/assets/coop_noteskin.py builds from SanityP1-5.
Run: python pi/tests/test_coop_noteskin.py"""
import os
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets"))
import coop_noteskin  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


SKIN = ["DownLeft Tap Note 6x1 (res 384x64).png", "Center Hold Body Active (res 64x1).png",
        "UpLeft Hold BottomCap Inactive (res 64x64).png", "UpRight Roll Body Inactive (res 64x64).png",
        "DownRight Roll BottomCap Active (res 64x64).png", "UpLeft Ready Receptor 3x1 (res 192x64).png",
        "UpLeft Explosion.lua", "_explosion 6x1.png", "logo.png", "metrics.ini", "NoteSkin.lua"]

check(coop_noteskin.player_name(2, "DownLeft Tap Note 6x1 (res 384x64).png") == "DownLeft P2 Tap Note 6x1 (res 384x64).png",
      "player_name puts P2 after the button")
check(coop_noteskin.player_name(5, "Center Hold Body Active (res 64x1).png") == "Center P5 Hold Body Active (res 64x1).png",
      "player_name for a hold body")
check(coop_noteskin.player_name(3, "UpLeft Ready Receptor 3x1 (res 192x64).png") is None, "receptors are not per player")
check(coop_noteskin.player_name(3, "UpLeft Explosion.lua") is None, "explosions are not per player")
check(coop_noteskin.player_name(2, "_explosion 6x1.png") is None, "files without a button are not per player")
check(coop_noteskin.player_name(4, "UpRight Roll Body Inactive (res 64x64).png") == "UpRight P4 Roll Body Inactive (res 64x64).png",
      "roll body")

plan = coop_noteskin.plan({n: list(SKIN) for n in range(1, 6)})
dests = [d for _, _, d in plan]
check(("SanityP1", "NoteSkin.lua", "NoteSkin.lua") not in plan, "SanityP1's NoteSkin.lua is not copied")
check(("SanityP1", "metrics.ini", "metrics.ini") not in plan, "SanityP1's metrics.ini is not copied")
check(("SanityP1", "logo.png", "logo.png") in plan, "the rest of SanityP1 is copied as is")
check(("SanityP1", "UpLeft Explosion.lua", "UpLeft Explosion.lua") in plan, "SanityP1's explosion is kept")
check(("SanityP3", "DownLeft Tap Note 6x1 (res 384x64).png", "DownLeft P3 Tap Note 6x1 (res 384x64).png") in plan,
      "SanityP3's tap note becomes P3")
check(len([d for d in dests if " P2 " in d]) == 5, "player 2 gets the 5 note files")
check(not any(" P1 " in d for d in dests), "no P1 names: player 1 uses the plain names")
check(len(dests) == len(set(dests)), "no destination is written twice")
check(len(plan) == 9 + 4 * 5, "9 files of SanityP1 and 5 note files for each of players 2-5")

check(coop_noteskin.METRICS == "[Global]\nFallbackNoteSkin=default\n\n[NoteDisplay]\nNumPlayers=5\n",
      "metrics declare 5 players")

# build: a temporary NoteSkins/pump with SanityP1-5
with tempfile.TemporaryDirectory() as root:
    for n in range(1, 6):
        os.makedirs(os.path.join(root, "SanityP%d" % n))
        for f in SKIN:
            with open(os.path.join(root, "SanityP%d" % n, f), "w") as fh:
                fh.write("P%d %s" % (n, f))
    lua = os.path.join(root, "src.lua")
    with open(lua, "w") as fh:
        fh.write("return {}")
    out = coop_noteskin.build(root, lua)
    files = sorted(os.listdir(out))
    check(os.path.basename(out) == "hexagono-coop", "build writes NoteSkins/pump/hexagono-coop")
    check("NoteSkin.lua" in files and "metrics.ini" in files, "build writes the script and the metrics")
    with open(os.path.join(out, "DownLeft P4 Tap Note 6x1 (res 384x64).png")) as fh:
        check(fh.read() == "P4 DownLeft Tap Note 6x1 (res 384x64).png", "P4's file comes from SanityP4")
    with open(os.path.join(out, "NoteSkin.lua")) as fh:
        check(fh.read() == "return {}", "the script is the repository's")
    check(len(files) == 9 + 4 * 5 + 2, "29 art files, the script and the metrics")
    os.remove(os.path.join(root, "SanityP5", "Center Hold Body Active (res 64x1).png"))
    check(coop_noteskin.missing(root) == ["SanityP5"], "missing lists an incomplete SanityP")

print("all passed" if failures == 0 else "%d failed" % failures)
sys.exit(1 if failures else 0)
