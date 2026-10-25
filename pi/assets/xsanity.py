#!/usr/bin/env python3
"""Copies the XSanity art the theme uses from XSanity 0.96.0 (an install, or its zip from
xsanity.net; later versions changed the art and ship fewer noteskins) into the theme,
and installs XSanity's Pump noteskins in OutFox:

  Graphics/XSanity/          level cards (ChanGraph), difficulty balls, grade labels,
                             title band, hearts, wheel frames
  Graphics/XSCommandWindow/  XSanity's command window (used when the Phoenix one is missing)
  NOTESKINS/pump/            the noteskins; XSanity's "default" becomes "xs_default" so it
                             does not hide OutFox's own default skin

The XSanity download has 11 Pump noteskins; --noteskins installs another set instead
(a folder or zip with a "pump" folder, like a backup of an existing NoteSkins/pump).
Files missing from the install are listed and skipped.
Usage: python3 xsanity.py XSANITY_DIR_OR_ZIP THEME_DIR NOTESKINS_DIR [--noteskins PATH]
"""
import argparse
import contextlib
import os
import re
import shutil
import sys
import tempfile
import zipfile

CHANNEL_SKIP = {"FAVORITES.PNG", "UCS.PNG"}
GRAPHICS = {   # file in Graphics/XSanity: path inside the XSanity theme
    "NAVARROW 4x4.png": "Graphics/ScreenSelectMusic/NAVARROW 4x4.png",
    "StepBall_Body 3x4.png": "Graphics/ScreenSelectMusic/DifficultyList/orbs/StepBall_Body 3x4.png",
    "StepList_Ballons 4x4.png": "Graphics/ScreenSelectMusic/DifficultyList/orbs/StepList_Ballons 4x4.png",
    "SSM-FULL-CURSOR 2x2.png": "Graphics/ScreenSelectMusic/DifficultyList/orbs/SSM-FULL-CURSOR 2x2.png",
    "THEME-HIGHSCOREPANEL 1x2.png": "Graphics/ScreenSelectMusic/DifficultyList/orbs/THEME-HIGHSCOREPANEL 1x2.png",
    "Difficulty_BigBalls frame.png": "Graphics/ScreenSelectMusic/DifficultyList/orbs/Difficulty_BigBalls frame.png",
    "sl_grade 1x17.png": "Graphics/ScreenSelectMusic/artifacts/sl_grade 1x17.png",
    "SSM-FULLARROWS 2x1.png": "Graphics/SSM-FULLARROWS 2x1.png",
    "SM-CHAN-GLOW.png": "Graphics/SM-CHAN-GLOW.png",
    "SM-WHEELPICK.png": "Graphics/SM-WHEELPICK.png",
    "SM-HEARTS 2x1.png": "Graphics/SM-HEARTS 2x1.png",
    "SM-BACKTITLE.png": "Graphics/SM-BACKTITLE.png",
    "SM-MINSONGBORDER.png": "Graphics/SM-MINSONGBORDER.png",
    "SM-BEATSONGBORDER.png": "Graphics/SM-BEATSONGBORDER.png",
}
COMMAND_WINDOW_SKIP_DIRS = {"previewhelp", "previewResume", "timing"}
TEXT_EXT = (".lua", ".ini", ".txt", ".xml")


def find_root(path):
    """The XSanity folder (the one with Themes/xsanity) inside path."""
    for d, dirs, _ in os.walk(path):
        if os.path.isdir(os.path.join(d, "Themes", "xsanity")):
            return d
        if d.count(os.sep) - path.count(os.sep) >= 3:
            dirs[:] = []
    sys.exit("no XSanity install (Themes/xsanity) under " + path)


def copy(src, dst, missing):
    if not os.path.isfile(src):
        missing.append(src)
        return
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy2(src, dst)


def art(xs, theme, missing):
    src_theme = os.path.join(xs, "Themes", "xsanity")
    out = os.path.join(theme, "Graphics", "XSanity")
    chan = os.path.join(src_theme, "ChanGraph")
    cards = 0
    for f in sorted(os.listdir(chan)) if os.path.isdir(chan) else []:
        if f.lower().endswith(".png") and f.upper() not in CHANNEL_SKIP:
            copy(os.path.join(chan, f), os.path.join(out, "ChanGraph", f), missing)
            cards += 1
    for name, rel in GRAPHICS.items():
        copy(os.path.join(src_theme, rel), os.path.join(out, name), missing)
    cw_src = os.path.join(src_theme, "Graphics", "CommandWindow")
    cw_out = os.path.join(theme, "Graphics", "XSCommandWindow")
    files = 0
    for d, dirs, fs in os.walk(cw_src):
        dirs[:] = [x for x in dirs if x not in COMMAND_WINDOW_SKIP_DIRS]
        for f in fs:
            if f.lower().startswith("resp_"):
                continue
            rel = os.path.relpath(os.path.join(d, f), cw_src)
            copy(os.path.join(d, f), os.path.join(cw_out, rel), missing)
            files += 1
    print("XSanity art: %d level cards, %d graphics, %d command window files" % (cards, len(GRAPHICS), files))


BRIGHT_LINE = re.compile(r"(?m)^([ \t]*)(BrightCommand[ \t]*=)")


def dim_like_bright(text):
    """Explosion actors that only react to "Bright" also react to "Dim".

    The engine plays "Bright" on a hit when the combo is above
    BrightGhostComboThreshold and "Dim" otherwise; it compares the combo before the
    hit, so the first note and the note after a miss are always "Dim". Most of these
    skins draw their explosion only on "Bright", so those hits had none. Each actor
    with an active BrightCommand gets a DimCommand that plays it; skins that handle
    "Dim" themselves are left alone."""
    if re.search(r"(?m)^[ \t]*DimCommand[ \t]*=", text):
        return text
    newline = "\r\n" if "\r\n" in text else "\n"
    return BRIGHT_LINE.sub(lambda m: m.group(1) + 'DimCommand=cmd(playcommand,"Bright");' + newline
                           + m.group(1) + m.group(2), text)


def fix_explosions(pump):
    """Applies dim_like_bright to every explosion actor of the pump noteskins."""
    changed = 0
    for d, _, fs in os.walk(pump):
        for f in fs:
            if "explosion" not in f.lower() or not f.lower().endswith(".lua"):
                continue
            p = os.path.join(d, f)
            text = open(p, encoding="utf-8", errors="surrogateescape", newline="").read()
            new = dim_like_bright(text)
            if new != text:
                open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write(new)
                changed += 1
    return changed


def noteskins(src, target):
    """Installs the skin folders of src (a pump noteskins folder) in target/pump."""
    if not src or not os.path.isdir(src):
        print("no pump noteskins found, noteskins skipped")
        return
    dst = os.path.join(target, "pump")
    count = 0
    for skin in sorted(os.listdir(src)):
        if skin == "common" or not os.path.isdir(os.path.join(src, skin)):
            continue
        name = "xs_default" if skin == "default" else skin
        if os.path.isdir(os.path.join(dst, name)):
            shutil.rmtree(os.path.join(dst, name))
        shutil.copytree(os.path.join(src, skin), os.path.join(dst, name))
        count += 1
    # references to the renamed default skin
    for d, _, fs in os.walk(dst):
        for f in fs:
            if not f.lower().endswith(TEXT_EXT):
                continue
            p = os.path.join(d, f)
            text = open(p, encoding="utf-8", errors="surrogateescape", newline="").read()
            new = re.sub(r"(?m)^([ \t]*FallbackNoteSkin[ \t]*=[ \t]*)default(?=[ \t]*\r?$)", r"\1xs_default", text)
            new = new.replace("NoteSkins/pump/default/", "NoteSkins/pump/xs_default/")
            if new != text:
                open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write(new)
    print("noteskins: %d, explosions shown on every hit: %d files" % (count, fix_explosions(dst)))


def extract(zip_path, dest, keep):
    """The members of a zip whose path contains one of the keep folders."""
    with zipfile.ZipFile(zip_path) as z:
        for info in z.infolist():
            name = info.filename.replace("\\", "/")   # zips made on Windows may use backslashes
            if info.is_dir() or not any(k in "/" + name for k in keep):
                continue
            target = os.path.join(dest, *name.split("/"))
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with z.open(info) as src, open(target, "wb") as out:
                shutil.copyfileobj(src, out)


def find_pump(path):
    """The first folder named "pump" under path (a NoteSkins/pump folder or a pack of it)."""
    if os.path.basename(os.path.normpath(path)) == "pump":
        return path
    for d, dirs, _ in os.walk(path):
        if "pump" in dirs:
            return os.path.join(d, "pump")
    return None


def unpacked(path, keep, stack):
    """path itself, or, when it is a zip, its keep folders unpacked next to it (removed
    when stack closes)."""
    if not zipfile.is_zipfile(path):
        return path
    tmp = stack.enter_context(tempfile.TemporaryDirectory(dir=os.path.dirname(os.path.abspath(path))))
    extract(path, tmp, keep)
    return tmp


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("xsanity", help="XSanity 0.96.0 install folder or zip")
    ap.add_argument("theme")
    ap.add_argument("noteskins_dir", help="OutFox's NoteSkins folder")
    ap.add_argument("--noteskins", help="folder or zip with the pump noteskins to install instead of the XSanity ones")
    a = ap.parse_args()
    with contextlib.ExitStack() as stack:
        xs = find_root(unpacked(a.xsanity, ("/Themes/xsanity/", "/NoteSkins/pump/"), stack))
        missing = []
        art(xs, a.theme, missing)
        if missing:
            print("missing in this XSanity install (skipped):")
            for m in missing:
                print("  " + os.path.relpath(m, xs))
        skins = find_pump(unpacked(a.noteskins, ("/pump/",), stack)) if a.noteskins else os.path.join(xs, "NoteSkins", "pump")
        noteskins(skins, a.noteskins_dir)


if __name__ == "__main__":
    main()
