#!/usr/bin/env python3
"""Builds the co-op noteskin NoteSkins/pump/hexagono-coop from XSanity's SanityP1-5 (one
color per player: red, blue, yellow, green, pink), so co-op charts show each player's
notes in their own color:

  - SanityP1 as it is (player 1's notes, receptors, explosions), without its script
  - the note art of SanityP2-5 (tap notes, hold and roll bodies and caps) renamed
    "<Button> P<n> <element>", the names OutFox asks a noteskin for when its metrics say
    NumPlayers=5
  - the script pi/config/noteskins/hexagono-coop/NoteSkin.lua and those metrics

The theme switches to it on co-op charts (Modules/Gameplay.Coop.lua). The art stays
XSanity's, so this runs on the machine and never goes to the repository.
Usage: python3 coop_noteskin.py NOTESKINS_PUMP_DIR
"""
import os
import re
import shutil
import sys

NAME = "hexagono-coop"
PLAYERS = 5
BUTTONS = ("DownLeft", "UpLeft", "Center", "UpRight", "DownRight")
PER_PLAYER = re.compile(r"^(%s) ((?:Tap Note|Hold Body|Hold BottomCap|Roll Body|Roll BottomCap)\b.*)$"
                        % "|".join(BUTTONS), re.IGNORECASE)
SKIPPED = {"noteskin.lua", "metrics.ini"}
METRICS = "[Global]\nFallbackNoteSkin=default\n\n[NoteDisplay]\nNumPlayers=%d\n" % PLAYERS
HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "..", "config", "noteskins", NAME, "NoteSkin.lua")


def player_name(n, filename):
    """SanityP<n>'s note art renamed for player n, or None for files every player shares."""
    m = PER_PLAYER.match(filename)
    return "%s P%d %s" % (m.group(1), n, m.group(2)) if m else None


def plan(files):
    """(source skin, source file, destination file) for files = {n: [file names]}."""
    out = [("SanityP1", f, f) for f in sorted(files.get(1, [])) if f.lower() not in SKIPPED]
    for n in range(2, PLAYERS + 1):
        for f in sorted(files.get(n, [])):
            dest = player_name(n, f)
            if dest:
                out.append(("SanityP%d" % n, f, dest))
    return out


def missing(pump):
    """The SanityP folders that are absent or lack one of SanityP1's note files."""
    first = os.path.join(pump, "SanityP1")
    if not os.path.isdir(first):
        return ["SanityP%d" % n for n in range(1, PLAYERS + 1)]
    needed = {f for f in os.listdir(first) if player_name(1, f)}
    out = []
    for n in range(2, PLAYERS + 1):
        folder = os.path.join(pump, "SanityP%d" % n)
        if not os.path.isdir(folder) or not needed <= set(os.listdir(folder)):
            out.append("SanityP%d" % n)
    return out


def build(pump, script=SCRIPT):
    files = {n: os.listdir(os.path.join(pump, "SanityP%d" % n)) for n in range(1, PLAYERS + 1)}
    dest = os.path.join(pump, NAME)
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    os.makedirs(dest)
    for skin, src, name in plan(files):
        shutil.copyfile(os.path.join(pump, skin, src), os.path.join(dest, name))
    shutil.copyfile(script, os.path.join(dest, "NoteSkin.lua"))
    with open(os.path.join(dest, "metrics.ini"), "w", newline="\n") as f:
        f.write(METRICS)
    return dest


def main():
    pump = sys.argv[1]
    lacking = missing(pump)
    if lacking:
        sys.exit("co-op noteskin: missing %s in %s" % (", ".join(lacking), pump))
    print("co-op noteskin written to", build(pump))


if __name__ == "__main__":
    main()
