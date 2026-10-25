"""Tests for the 60 Hz mode picker (display_60hz.pick). Run: python pi/tests/test_display60.py
tv.json holds the modes of a Samsung QCQ90 TV (wlr-randr --json), which prefers 4K at 30 Hz."""
import importlib.util
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
from importlib.machinery import SourceFileLoader
loader = SourceFileLoader("display_60hz", os.path.join(HERE, "..", "config", "bin", "display-60hz"))  # the script has no .py extension
spec = importlib.util.spec_from_loader("display_60hz", loader)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
pick = mod.pick


def m(w, h, r, preferred=False):
    return {"width": w, "height": h, "refresh": r, "preferred": preferred, "current": False}


def res(mode):
    return None if mode is None else (mode["width"], mode["height"], round(mode["refresh"], 3))


failures = 0


def check(name, got, want):
    global failures
    ok = got == want
    failures += 0 if ok else 1
    print(("ok   " if ok else "FAIL ") + name + ("" if ok else f": got {got}, want {want}"))


tv = json.load(open(os.path.join(HERE, "tv.json")))[0]["modes"]
check("4K TV whose preferred mode is 4K30 gets 1080p60", res(pick(tv)), (1920, 1080, 60.0))

check("16:10 monitor keeps its native 1920x1200 at 60",
      res(pick([m(1920, 1200, 59.95, True), m(1920, 1080, 60.0), m(1680, 1050, 59.88)])), (1920, 1200, 59.95))

check("1440p 144 Hz monitor gets 1080p60, not 1440p or 144 Hz",
      res(pick([m(2560, 1440, 143.97, True), m(2560, 1440, 59.95), m(1920, 1080, 144.0), m(1920, 1080, 60.0)])), (1920, 1080, 60.0))

check("old 5:4 monitor gets 1280x1024 at 60, not 75",
      res(pick([m(1280, 1024, 75.02, True), m(1280, 1024, 60.02), m(1024, 768, 60.0)])), (1280, 1024, 60.02))

check("a screen without any 60 Hz mode is left alone",
      res(pick([m(1920, 1080, 50.0, True), m(720, 576, 50.0)])), None)

check("4K60 monitor gets 1080p60",
      res(pick([m(3840, 2160, 60.0, True), m(2560, 1440, 59.95), m(1920, 1080, 60.0)])), (1920, 1080, 60.0))

check("when every 60 Hz mode is above the limit, the smallest one is used",
      res(pick([m(3840, 2160, 60.0, True), m(2560, 1440, 59.95)])), (2560, 1440, 59.95))

check("exact 60.000 wins over 59.94 at the same size",
      res(pick([m(1920, 1080, 59.94), m(1920, 1080, 60.0), m(3840, 2160, 30.0, True)])), (1920, 1080, 60.0))

check("1366x768 laptop panel keeps its native mode",
      res(pick([m(1366, 768, 60.0, True), m(1280, 720, 60.0), m(1024, 768, 60.0)])), (1366, 768, 60.0))

print("FAILED" if failures else "all passed", failures)
sys.exit(1 if failures else 0)
