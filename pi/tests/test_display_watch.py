"""Tests for display-watch (which screens count as real, when the game restarts).
Run: python pi/tests/test_display_watch.py"""
import importlib.util
import json
import os
import sys
from importlib.machinery import SourceFileLoader

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = os.path.join(HERE, "..", "config", "bin")
loader = SourceFileLoader("display_watch", os.path.join(BIN, "display-watch"))  # no .py extension
spec = importlib.util.spec_from_loader("display_watch", loader)
watch = importlib.util.module_from_spec(spec)
spec.loader.exec_module(watch)

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


tv = json.load(open(os.path.join(HERE, "tv.json")))[0]


def mode(w, h, r, preferred=False, current=False):
    return {"width": w, "height": h, "refresh": r, "preferred": preferred, "current": current}


# HDMI with the TV off: the port stays connected, no EDID, the kernel's generic modes
no_edid = {"name": "HDMI-A-1", "enabled": True, "make": "", "model": "", "serial": "",
           "modes": [mode(1024, 768, 60.004, True, True), mode(800, 600, 60.317), mode(640, 480, 59.94)]}
unknown = dict(no_edid, make="Unknown", model="Unknown", serial="Unknown")
small_monitor = dict(no_edid, make="Dell Inc.", model="1704FP", serial="")

check(watch.real(tv), "a TV with EDID is a real screen")
check(not watch.real(no_edid), "generic 1024x768 modes without EDID are not")
check(not watch.real(unknown), "make and model 'Unknown' count as no EDID")
check(watch.real(small_monitor), "a small monitor that reports its make is real")
check(not watch.real(dict(tv, enabled=False)), "a disabled output is not a screen")
# while HDMI goes away (the TV being turned on) the compositor shows a virtual output
noop = {"name": "NOOP-1", "enabled": True, "make": "", "model": "", "serial": "",
        "modes": [mode(1920, 1080, 0.0, False, True)]}
check(not watch.real(noop), "the compositor's virtual NOOP output is not a screen")
check(not watch.real(dict(noop, name="HEADLESS-1")), "nor a HEADLESS one")

key_tv = watch.screen_key([tv])
check(key_tv and "Samsung" in key_tv and "QCQ90" in key_tv, "the key names the screen")
check(watch.screen_key([no_edid]) == "", "no real screen: empty key")
check(watch.screen_key([tv]) == watch.screen_key([dict(tv)]), "same screen, same key")

tv_4k = dict(tv, modes=[dict(m, current=(m["width"] == 3840 and m["refresh"] < 31)) for m in tv["modes"]])
check(watch.screen_key([tv_4k]) != key_tv, "the key includes the current mode (4K at 30 Hz is not 1080p at 60)")

# restart only when the game runs on a screen other than the current real one
check(watch.should_restart("A 1920x1080", "B 1920x1080", True), "different screen while the game runs: restart")
check(not watch.should_restart("A 1920x1080", "A 1920x1080", True), "same screen: no restart")
check(not watch.should_restart("A 1920x1080", "", True), "no real screen now (TV off): no restart")
check(not watch.should_restart("", "A 1920x1080", False), "game not running: no restart")
check(not watch.should_restart(None, "A 1920x1080", True), "start screen unknown: no restart")
# the screen went away while the game ran (TV turned off and on): its window went
# through the virtual output, so it restarts even on the same screen
check(watch.should_restart("A 1920x1080", "A 1920x1080", True, lost=True), "screen came back after going away: restart")
check(not watch.should_restart("A 1920x1080", "A 1920x1080", False, lost=True), "came back but the game is not running: no restart")
check(not watch.should_restart("A 1920x1080", "", True, lost=True), "still no screen: no restart yet")

print("all passed" if failures == 0 else "%d failed" % failures, failures)
sys.exit(1 if failures else 0)
