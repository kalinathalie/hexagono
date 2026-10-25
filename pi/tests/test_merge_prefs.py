"""Tests for pi/merge_prefs.py (the keys setup.sh sets in OutFox's Preferences.ini).
Run: python pi/tests/test_merge_prefs.py"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import merge_prefs  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


KIT = """; comment
[Options]
CurrentGame=pump
Theme=Infinitesimal
DisplayWidth=1280
; per game
[Game-pump]
Announcer=
Theme=Infinitesimal
"""


def sections(text):
    """{section: {key: value}} and the keys seen twice in one section."""
    out, dup, cur = {}, [], None
    for line in text.splitlines():
        if line.startswith("["):
            cur = line.strip("[]")
            out.setdefault(cur, {})
        elif "=" in line and not line.startswith(";"):
            k, v = line.split("=", 1)
            if k in out[cur]:
                dup.append((cur, k))
            out[cur][k] = v
    return out, dup


# a new install: OutFox has not written anything yet
fresh, dup = sections(merge_prefs.merge(KIT, ""))
check(fresh.get("Options", {}).get("Theme") == "Infinitesimal", "fresh: Theme under [Options]")
check(fresh.get("Game-pump", {}).get("Theme") == "Infinitesimal",
      "fresh: Theme under [Game-pump], which OutFox reads at start (without it, the default theme opens)")
check(fresh.get("Game-pump", {}).get("Announcer") == "", "fresh: empty values are kept")
check(not dup, "fresh: no key twice")

# the file OutFox writes: keys spread over [Options|-|...] subsections, another theme per game
OUTFOX = """[Options]

[Options|-|GameSettings]
CurrentGame=dance
Theme=default

[Options|-|DisplaySettings]
DisplayWidth=1920
Windowed=1

[Game-dance]
Theme=default

[Game-pump]
Announcer=
DefaultModifiers=FailImmediate, Overhead
Theme=default
"""
merged = merge_prefs.merge(KIT, OUTFOX)
got, dup = sections(merged)
check(got["Options|-|GameSettings"]["Theme"] == "Infinitesimal" and got["Options|-|GameSettings"]["CurrentGame"] == "pump",
      "existing: [Options] keys are set in the subsection where OutFox keeps them")
check(got["Options|-|DisplaySettings"]["DisplayWidth"] == "1280" and got["Options|-|DisplaySettings"]["Windowed"] == "1",
      "existing: other keys are left alone")
check("DisplayWidth" not in got["Options"] and "Theme" not in got["Options"], "existing: no copy added under [Options]")
check(got["Game-pump"]["Theme"] == "Infinitesimal" and got["Game-pump"]["DefaultModifiers"] == "FailImmediate, Overhead",
      "existing: [Game-pump] Theme set, its other keys kept")
check(got["Game-dance"]["Theme"] == "default", "existing: other games keep their theme")
check(not dup, "existing: no key twice")
check(merge_prefs.merge(KIT, merged) == merged, "running it again changes nothing")

# a file without the per-game section gets it
no_game, _ = sections(merge_prefs.merge(KIT, "[Options]\nCurrentGame=pump\n"))
check(no_game.get("Game-pump", {}).get("Theme") == "Infinitesimal", "missing [Game-pump] is added")

print("all passed" if failures == 0 else "%d failed" % failures, failures)
sys.exit(1 if failures else 0)
