"""Tests for the names, the score digit font and the labels pi/assets/lbpiu.py builds.
Run: python pi/tests/test_lbpiu.py"""
import os
import sys

from PIL import Image, ImageFont

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets"))
import lbpiu  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


# plates: the scoreboard's short names become the theme's plate names
check(lbpiu.PLATES == {"PG": "PERFECT GAME", "UG": "ULTIMATE GAME", "EG": "EXTREME GAME", "SG": "SUPERB GAME",
                       "MG": "MARVELOUS GAME", "TG": "TALENTED GAME", "FG": "FAIR GAME", "RG": "ROUGH GAME"},
      "PLATES maps the 8 short names to the plate names")

# balls: SINGLE and DOUBLE 1 to 29, CO-OP x2 to x5
names = lbpiu.ball_names()
check(names[0] == "S01" and names[28] == "S29", "single balls S01 to S29")
check(names[29] == "D01" and names[57] == "D29", "double balls D01 to D29")
check(names[58:] == ["C02", "C03", "C04", "C05"], "co-op balls C02 to C05")
check(len(names) == 62 and len(set(names)) == 62, "62 distinct balls")

# digit font: 4x4 cells of 64 px, the digits, and z, a dim zero for the leading zeros
ini = lbpiu.digit_font_ini()
check("[numbers]" in ini and "Line 0=0123" in ini and "Line 1=4567" in ini and "Line 2=89z," in ini,
      "digit_font_ini maps 0-9 and z")
check("\n0=50\n" in ini and "\n10=50\n" in ini and "\n11=16\n" in ini, "digits and z advance 50 px, the rest 16")
check("DrawExtraPixelsLeft=7" in ini and "DrawExtraPixelsRight=7" in ini, "each glyph draws its whole 64 px cell")

digits = {}
for d in range(10):
    im = Image.new("RGBA", (50, 62), (0, 0, 0, 0))
    im.paste((255, 255, 255, 200), (10, 5, 40, 57))
    digits[str(d)] = im
sheet = lbpiu.digit_sheet(digits)
check(sheet.size == (256, 256) and sheet.mode == "RGBA", "digit_sheet is a 256 px RGBA sheet")
check(sheet.getpixel((32, 32))[3] == 200, "the 0 sits in the first cell")
check(sheet.getpixel((32 + 64 * 2, 32 + 64 * 2))[3] == 70, "z (third row, third cell) is the 0 at 35% alpha")
check(sheet.getpixel((32 + 64 * 3, 32 + 64 * 3))[3] == 0, "unused cells stay empty")

# dim scales the alpha only
dimmed = lbpiu.dim(Image.new("RGBA", (1, 1), (10, 20, 30, 200)), 0.5)
check(dimmed.getpixel((0, 0)) == (10, 20, 30, 100), "dim halves the alpha and keeps the color")

# labels: the scoreboard's colors, top to bottom
keys = [k for k, _, _, _ in lbpiu.LABELS]
check(keys == ["_perfect", "_great", "_good", "_bad", "_miss", "_maxcombo", "_cal", "_score"], "LABELS order")
check(lbpiu.LABELS[0][1:] == ("PERFECT", (17, 238, 238), (0, 136, 204)), "PERFECT: cyan to blue")
check(lbpiu.LABELS[6][1] == "KCAL", "the kcal row says KCAL")

# gradient: the top color above 25% of the height, the bottom one below 75%
mask = Image.new("L", (4, 9), 255)
g = lbpiu.gradient_fill(mask, (255, 0, 0), (0, 0, 255))
check(g.getpixel((0, 0)) == (255, 0, 0, 255) and g.getpixel((0, 2)) == (255, 0, 0, 255), "top quarter is the top color")
check(g.getpixel((0, 8)) == (0, 0, 255, 255) and g.getpixel((0, 6)) == (0, 0, 255, 255), "bottom quarter is the bottom color")
mid = g.getpixel((0, 4))
check(120 <= mid[0] <= 135 and 120 <= mid[2] <= 135, "the middle is half way")
hole = Image.new("L", (2, 2), 0)
check(lbpiu.gradient_fill(hole, (255, 0, 0), (0, 0, 255)).getpixel((0, 0))[3] == 0, "outside the text stays clear")

# a label: tight, cap height as asked, black outline around the colored letters
font = ImageFont.load_default(size=60)
lab = lbpiu.label_image("GOOD", font, (255, 255, 51), (204, 170, 17), cap=40)
check(lab.mode == "RGBA", "label_image is RGBA")
check(40 <= lab.height <= 40 + 2 * (lbpiu.OUTLINE + lbpiu.SHADOW) + 4, "label height is the cap height plus outline")
px = list(lab.getdata())
check(any(p[3] == 255 and max(p[:3]) < 40 for p in px), "label has a dark outline")
check(any(p[3] == 255 and p[0] > 180 and p[1] > 150 for p in px), "label has the yellow letters")

check(lbpiu.info_text(62) == "[Scoreboard]\nSource=" + lbpiu.BASE + "\nBalls=62\n", "info_text")

print("all passed" if failures == 0 else "%d failed" % failures)
sys.exit(1 if failures else 0)
