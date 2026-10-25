#!/usr/bin/env python3
"""Builds the stage break animation (Graphics/Phoenix/StageBreak) from the Pump It Up
Phoenix 2 "Hey!! Why don't you just get up and dance man? & Game Over" video on
YouTube: from the first frame after the frozen gameplay (the arcade holds the last
gameplay frame for a moment) to the end of the "HEY! WHY DON'T YOU JUST GET UP AND
DANCE MAN?" screen, which BGAnimations/ScreenGameplay failed plays when a player
breaks the stage (40 misses in a row).

  hey.mp4    source frames 102 to 492 (60 fps upload, 30 distinct frames per second;
             frame 101 is torn between gameplay and the animation), 1280x720 at 30 fps
             in full-range color like the title video; 39 px are cut from each side
             and 44 px from the bottom (kept 16:9) to drop the arcade's "CREDIT(S)"
             line burned into the video
  hey.ogg    the same 6.5 s of audio: the effects and the voice (the song that was
             playing stops at 1.58 s, before the first frame)
  info.ini   Length=<seconds>

Needs ffmpeg and, to download, yt-dlp with node. Usage:
  python3 stagebreak.py OUT_DIR [--source VIDEO] [--work DIR] [--yt-dlp CMD]
"""
import argparse
import os
import subprocess
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import title  # noqa: E402  (same folder: download, check_source, write_wav, X264)

URL = "https://youtu.be/YNYPReO9Kfo"
FIRST, END = 102, 493         # source frames (60 fps): first of the animation, first of the results screen
SONG_UNTIL = 1.58             # seconds into the source where the arcade's song stops (muted if before FIRST)
VIDEO = ("trim=start_frame=%d:end_frame=%d,setpts=PTS-STARTPTS,fps=30,crop=1842:1036:39:0,"
         "scale=1280:720:flags=lanczos:in_range=tv:out_range=pc" % (FIRST, END))
FADE = 480                    # 10 ms


def video(src, out):
    title.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-an", "-vf", VIDEO] + title.X264
              + [os.path.join(out, "hey.mp4")])


def audio(src, out, work):
    rate = title.AUDIO_RATE
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-vn", "-ac", "2", "-ar", str(rate),
                          "-f", "s16le", "-"], capture_output=True, check=True).stdout
    x = np.frombuffer(raw, "<i2").reshape(-1, 2).astype(np.float64)
    start, end = round(FIRST / 60 * rate), round(END / 60 * rate)
    clip = x[start:end].copy()
    quiet = max(0, round((SONG_UNTIL - FIRST / 60) * rate))
    clip[:quiet] = 0
    fade = min(FADE, len(clip) - quiet)
    clip[quiet:quiet + fade] *= np.linspace(0, 1, fade)[:, None]
    wav = os.path.join(work, "hey.wav")
    title.write_wav(wav, np.clip(np.round(clip), -32768, 32767))
    title.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", os.path.join(out, "hey.ogg")])


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("out")
    ap.add_argument("--source", help="the downloaded YouTube video (skips the download)")
    ap.add_argument("--work", default=os.path.join(os.path.expanduser("~"), ".cache", "hexagono-assets", "stagebreak"))
    ap.add_argument("--yt-dlp", default="yt-dlp", help="yt-dlp command")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    os.makedirs(a.work, exist_ok=True)
    src = a.source or title.download(a.work, a.yt_dlp.split(), URL)
    rate = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=r_frame_rate",
                           "-of", "csv=p=0", src], capture_output=True, text=True, check=True).stdout.strip()
    if rate != "60/1":
        sys.exit("unexpected source video (%s fps): the cut points are for the 60 fps upload" % rate)
    video(src, a.out)
    audio(src, a.out, a.work)
    with open(os.path.join(a.out, "info.ini"), "w", newline="\n") as f:
        f.write("; Phoenix 2 stage break animation (youtu.be/YNYPReO9Kfo)\n[StageBreak]\nLength=%.6f\n" % ((END - FIRST) / 60))
    print("stage break animation written to", a.out)


if __name__ == "__main__":
    main()
