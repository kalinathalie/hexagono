#!/usr/bin/env python3
"""Builds the title screen video (Graphics/Phoenix/Title) from the Pump It Up Phoenix 2
title video on YouTube, the way the theme plays it (Scripts/06 PhoenixTitle.lua):

  intro.mp4 + intro.ogg   played once: warning, logos and trailer, up to the point
                          where the attract loop starts repeating
  loop.mp4 + loop.ogg     then repeated with no visible seam: the video loop is one
                          842-frame period of the 60 fps source (14.033 s), the audio
                          loop one 11.026 s music cycle that fades back into its start
  info.ini                the lengths the theme needs

The cut points were measured once on the YouTube upload (format 399, AV1 1080p60,
with Opus audio at 48 kHz). The video is 1280x720 at 30 fps (the trailer itself has
30 distinct frames per second) in full-range color: OutFox shows video levels as they
are, so TV-range video would look washed out.

Needs ffmpeg and, to download, yt-dlp with a JavaScript runtime (node).
Usage: python3 title.py OUT_DIR [--source VIDEO] [--work DIR] [--yt-dlp CMD]
"""
import argparse
import json
import os
import subprocess
import sys
import wave

import numpy as np

URL = "https://youtu.be/TEJaL2LWY8w"
INTRO_FRAMES = 6028      # source frames (60 fps) before the attract loop repeats
LOOP_END = 6870          # end of the 842-frame loop period
AUDIO_RATE = 48000
AUDIO_CUT = 4821208      # samples: 100.441833 s, where the audio loop starts (24.8 ms before the video cut)
AUDIO_LOOP = 529235      # samples in one music cycle: 11.025729 s
FADE = 2400              # 50 ms crossfade at the end of the loop, back into its start
TRAILER_START = 24.5     # seconds into the intro where the green trailer begins (title prompts appear)
VIDEO = ("setpts=PTS-STARTPTS,fps=30,scale=1280:720:flags=lanczos:in_range=tv:out_range=pc")
X264 = ["-c:v", "libx264", "-preset", "slow", "-crf", "16", "-pix_fmt", "yuv420p", "-color_range", "pc",
        "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-g", "60", "-movflags", "+faststart"]


def run(cmd):
    subprocess.run(cmd, check=True)


def download(work, ytdlp):
    target = os.path.join(work, "source.mkv")
    if not os.path.exists(target):
        run(ytdlp + ["--no-playlist", "--js-runtimes", "node", "--retries", "10",
                     "-f", "bv*[height<=1080][fps>=50]+ba/bv*[height<=1080]+ba",
                     "--merge-output-format", "mkv", "-o", os.path.join(work, "source.%(ext)s"), URL])
    return target


def check_source(path):
    info = json.loads(subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                                      "stream=r_frame_rate:format=duration", "-of", "json", path],
                                     capture_output=True, check=True).stdout)
    rate, length = info["streams"][0]["r_frame_rate"], float(info["format"]["duration"])
    if rate != "60/1" or length < LOOP_END / 60:
        sys.exit("unexpected source video (%s fps, %.1f s): the cut points are for the 60 fps upload" % (rate, length))


def video(src, out):
    for name, trim in (("intro", "trim=end_frame=%d" % INTRO_FRAMES),
                       ("loop", "trim=start_frame=%d:end_frame=%d" % (INTRO_FRAMES, LOOP_END))):
        run(["ffmpeg", "-v", "error", "-y", "-i", src, "-an", "-vf", trim + "," + VIDEO] + X264 + [os.path.join(out, name + ".mp4")])


def write_wav(path, samples):
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(AUDIO_RATE)
        w.writeframes(samples.astype("<i2").tobytes())


def audio(src, out, work):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", src, "-vn", "-ac", "2", "-ar", str(AUDIO_RATE),
                          "-f", "s16le", "-"], capture_output=True, check=True).stdout
    x = np.frombuffer(raw, "<i2").reshape(-1, 2).astype(np.float64)
    intro = x[:AUDIO_CUT]
    loop = x[AUDIO_CUT:AUDIO_CUT + AUDIO_LOOP].copy()
    w = np.linspace(0, 1, FADE)[:, None]
    loop[-FADE:] = x[AUDIO_CUT + AUDIO_LOOP - FADE:AUDIO_CUT + AUDIO_LOOP] * (1 - w) + x[AUDIO_CUT - FADE:AUDIO_CUT] * w
    for name, samples in (("intro", intro), ("loop", loop)):
        wav = os.path.join(work, name + ".wav")
        write_wav(wav, np.clip(np.round(samples), -32768, 32767))
        run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", os.path.join(out, name + ".ogg")])


def info(out):
    with open(os.path.join(out, "info.ini"), "w", newline="\n") as f:
        f.write("; Phoenix 2 title video (youtu.be/TEJaL2LWY8w), cut where the attract loop repeats\n"
                "; intro: 0 to the cut; loop video: 421 frames at 30 fps; loop audio: one 11.026 s music cycle\n"
                "[Title]\n"
                "IntroVideo=%.6f\nIntroAudio=%.6f\nLoopAudio=%.6f\nTrailerStart=%s\n"
                % (INTRO_FRAMES / 2 / 30, AUDIO_CUT / AUDIO_RATE, AUDIO_LOOP / AUDIO_RATE, TRAILER_START))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("out")
    ap.add_argument("--source", help="the downloaded YouTube video (skips the download)")
    ap.add_argument("--work", default=os.path.join(os.path.expanduser("~"), ".cache", "hexagono-assets", "title"))
    ap.add_argument("--yt-dlp", default="yt-dlp", help="yt-dlp command")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    os.makedirs(a.work, exist_ok=True)
    src = a.source or download(a.work, a.yt_dlp.split())
    check_source(src)
    video(src, a.out)
    audio(src, a.out, a.work)
    info(a.out)
    print("title video written to", a.out)


if __name__ == "__main__":
    main()
