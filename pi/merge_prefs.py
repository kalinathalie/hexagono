#!/usr/bin/env python3
"""Sets the keys of the kit's Preferences.ini (pi/config/outfox) in OutFox's own
Preferences.ini, leaving every other key as it is:

  [Options] keys   OutFox keeps them in subsections ([Options|-|GameSettings],
                   [Options|-|DisplaySettings], ...): each one is set where it already
                   is; new ones go under [Options]
  other sections   matched by name and added when missing. [Game-pump] matters: at
                   start OutFox takes the theme of the current game from there, over
                   [Options], so without it a new install opens OutFox's default theme

Usage: python3 merge_prefs.py KIT_PREFERENCES TARGET_PREFERENCES
"""
import os
import re
import sys

KEY = re.compile(r"^([A-Za-z0-9_]+)=(.*)$")
SECTION = re.compile(r"^\[(.*)\]$")


def parse_kit(text):
    """[(section, key, value)] in file order; comments and blank lines skipped."""
    out, cur = [], None
    for line in text.splitlines():
        line = line.strip()
        m = SECTION.match(line)
        if m:
            cur = m.group(1)
            continue
        m = KEY.match(line)
        if m and cur:
            out.append((cur, m.group(1), m.group(2)))
    return out


def in_section(name, wanted):
    if wanted == "Options":
        return name == "Options" or name.startswith("Options|")
    return name == wanted


def block_end(lines, header):
    """Index after the last non-blank line of the section that starts at header."""
    end = header + 1
    for i in range(header + 1, len(lines)):
        if SECTION.match(lines[i].strip()):
            break
        if lines[i].strip():
            end = i + 1
    return end


def merge(kit_text, target_text):
    lines = target_text.splitlines()
    for section, key, value in parse_kit(kit_text):
        cur, found, header = None, False, None
        for i, line in enumerate(lines):
            m = SECTION.match(line.strip())
            if m:
                cur = m.group(1)
                if cur == section and header is None:
                    header = i
                continue
            m = KEY.match(line.strip())
            if m and m.group(1) == key and cur is not None and in_section(cur, section):
                lines[i] = key + "=" + value
                found = True
        if found:
            continue
        if header is None:
            if section == "Options":
                lines.insert(0, "[Options]")
                header = 0
            else:
                if lines and lines[-1].strip():
                    lines.append("")
                lines.append("[%s]" % section)
                header = len(lines) - 1
        lines.insert(block_end(lines, header), key + "=" + value)
    return "\n".join(lines) + "\n"


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__.split("Usage: ")[1].strip())
    kit, target = sys.argv[1], sys.argv[2]
    kit_text = open(kit, encoding="utf-8").read()
    old = open(target, encoding="utf-8").read() if os.path.exists(target) else ""
    open(target, "w", encoding="utf-8").write(merge(kit_text, old))
    print("Preferences.ini: %d keys set" % len(parse_kit(kit_text)))


if __name__ == "__main__":
    main()
