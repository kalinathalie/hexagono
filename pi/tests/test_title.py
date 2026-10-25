"""Tests for the timings pi/assets/title.py writes to info.ini.
Run: python pi/tests/test_title.py"""
import os
import re
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets"))
import title  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


with tempfile.TemporaryDirectory() as out:
    title.info(out)
    text = open(os.path.join(out, "info.ini")).read()
values = {k: float(v) for k, v in re.findall(r"(?m)^(\w+)=([\d.]+)$", text)}

check(abs(values.get("IntroVideo", 0) - 100.466667) < 1e-5, "intro video length")
# the title prompts appear with the game logo: where the attract loop first starts,
# one loop period (842 source frames) before the cut, after the trailer's end card
check(abs(values.get("LogoStart", 0) - 86.433333) < 1e-5, "logo start: %s" % values.get("LogoStart"))
check("TrailerStart" not in values, "no trailer start (the prompts no longer show over the trailer)")

print("all passed" if failures == 0 else "%d failed" % failures, failures)
sys.exit(1 if failures else 0)
