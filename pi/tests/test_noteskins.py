"""Tests for the noteskin fix in pi/assets/xsanity.py (explosions that only react to
"Bright" also react to "Dim"). Run: python pi/tests/test_noteskins.py"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets"))
import xsanity  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


infinity = '''return Def.ActorFrame {
\tLoadActor("_Tap Explosion Bright") .. {
\t\tInitCommand=cmd(blend,"BlendMode_Add";diffusealpha,0);
\t\tPressCommand=cmd(playcommand,"Bright");
\t\tBrightCommand=cmd(stoptweening;setstate,0;diffusealpha,1;sleep,0.28;diffusealpha,0);
\t};
\tDef.Sprite {
\t\t--BrightCommand=cmd(old;one);
\t\tBrightCommand=cmd(finishtweening;diffusealpha,1);
\t};
}'''
fixed = xsanity.dim_like_bright(infinity)
check(fixed.count('DimCommand=cmd(playcommand,"Bright");') == 2, "one Dim per active Bright command")
check('\t\tDimCommand=cmd(playcommand,"Bright");\n\t\tBrightCommand=cmd(stoptweening' in fixed, "same indentation, right before it")
check("--BrightCommand=cmd(old;one);" in fixed and "--DimCommand" not in fixed, "commented lines are left alone")
check(xsanity.dim_like_bright(fixed) == fixed, "running it again changes nothing")

own_dim = infinity.replace("PressCommand", "DimCommand=cmd(diffusealpha,0.5);\n\t\tPressCommand")
check(xsanity.dim_like_bright(own_dim) == own_dim, "a skin that handles Dim itself is left alone")
judged = 'Def.Sprite { W1Command=cmd(playcommand,"Glow"); GlowCommand=cmd(diffusealpha,1); }'
check(xsanity.dim_like_bright(judged) == judged, "a skin without Bright commands is left alone")
check(xsanity.dim_like_bright(infinity.replace("\n", "\r\n")).count("DimCommand") == 2, "CRLF files too")

print("all passed" if failures == 0 else "%d failed" % failures, failures)
sys.exit(1 if failures else 0)
