"""Tests for pi/assets/avatars.py (the Phoenix player icons). No network.
Run: python pi/tests/test_avatars.py"""
import os
import re
import ssl
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets"))
import avatars  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


check(len(avatars.IDS) == 165, "165 icons (got %d)" % len(avatars.IDS))
check(len(set(avatars.IDS)) == len(avatars.IDS), "no icon listed twice")
check(all(re.fullmatch(r"[0-9a-f]{32}", i) for i in avatars.IDS), "every id is a 32-digit hex name")
check(avatars.IDS[0] == "767d1a3db8c5b1dbb6ea631cf8684acb", "the list keeps the site's order")
check(avatars.file_name(1) == "PIU 001.png" and avatars.file_name(165) == "PIU 165.png",
      "files are numbered in that order, so the photo list keeps it")

ctx = avatars.make_context(None)
check(ctx.verify_mode == ssl.CERT_REQUIRED and ctx.check_hostname, "the certificate is checked")
partial = getattr(ssl, "VERIFY_X509_PARTIAL_CHAIN", 0)
check(not (ctx.verify_flags & partial),
      "the chain must reach a trusted root (the intermediate fetched over http is no root)")

check(avatars.is_png(b"\x89PNG\r\n\x1a\n" + b"\0" * 16), "a PNG is accepted")
check(not avatars.is_png(b"<html>error</html>"), "an error page is not saved as an icon")

print("all passed" if failures == 0 else "%d failed" % failures, failures)
sys.exit(1 if failures else 0)
