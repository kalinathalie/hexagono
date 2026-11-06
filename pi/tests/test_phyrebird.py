"""Tests for the result screen files and the wav length pi/assets/phyrebird.py writes.
Run: python pi/tests/test_phyrebird.py"""
import io
import os
import struct
import sys
import wave

from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets"))
import phyrebird  # noqa: E402

failures = 0


def check(cond, msg):
    global failures
    print(("ok   " if cond else "FAIL ") + msg)
    failures += 0 if cond else 1


GRADES = ["SSS+", "SSS", "SS+", "SS", "S+", "S", "AAA+", "AAA", "AA+", "AA", "A+", "A", "B", "C", "D", "F"]
PLATES = ["PERFECT GAME", "ULTIMATE GAME", "EXTREME GAME", "SUPERB GAME", "MARVELOUS GAME", "TALENTED GAME",
          "FAIR GAME", "ROUGH GAME"]
PARTS = ["_perfect", "_great", "_good", "_bad", "_miss", "_maxcombo", "_cal", "_shine", "_score_bg"]
SCREEN = "Themes/Fiesta 2/Graphics/ScreenEvaluation/"
RANK = "Themes/Fiesta 2/Sounds/Rank/"
BGM = "Themes/Fiesta 2/Sounds/Sounds/vanilla/RESULT_BGM (loop).wav"
OUTSIDE = [
    "Themes/Fiesta 2/Graphics/ScreenEvaluation/old/R_A.png",
    "Themes/Fiesta 2/Graphics/ScreenEvaluation/resources/FAIR GAME.png",
    "Themes/Fiesta 2/Graphics/ScreenEvaluation/EvaluationGrades.psd",
    "Themes/Fiesta 2/Graphics/ScreenEvaluation/STAR.png",
    "Themes/Fiesta 2/Graphics/ScreenEvaluation/_total.png",
    "Themes/Fiesta 2/Sounds/PrimeRank/RANK_A_B.mp3",
    "Themes/Fiesta 2/Sounds/Rank/CROWD_GOLD.mp3",
    "Themes/Fiesta 2/Sounds/Rank/GLASS.mp3",
    "Themes/Fiesta 2/Sounds/Rank/RANK.mp3",
    "Themes/Fiesta 2/Sounds/Sounds/RESULT_BGM (loop).mp3",
]


def expected_pairs():
    """(repo path, destination under Graphics/Phoenix/Evaluation) for the 82 wanted files."""
    pairs = []
    for g in GRADES:
        for side in ("R", "B"):
            pairs.append((SCREEN + side + "_" + g + ".png", side + "_" + g + ".png"))
    for name in PLATES + PARTS:
        pairs.append((SCREEN + name + ".png", name + ".png"))
    for g in GRADES:
        for side in ("R", "B"):
            name = "RANK_" + g + "_" + side + ".mp3"
            pairs.append((RANK + name, "Rank/" + name))
    pairs.append((BGM, "RESULT_BGM (loop).wav"))
    return pairs


def make_wav(frames=44100):
    buf = io.BytesIO()
    with wave.open(buf, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(22050)
        w.writeframes(b"\0" * (frames * 2 * 2))
    return buf.getvalue()


def with_odd_list_chunk(wav):
    """The same WAV with a 5-byte LIST chunk (plus its pad byte) before the data chunk."""
    at = wav.index(b"data")
    out = wav[:at] + b"LIST" + struct.pack("<I", 5) + b"abcde" + b"\0" + wav[at:]
    return out[:4] + struct.pack("<I", len(out) - 8) + out[8:]


def raises_value_error(data):
    try:
        phyrebird.wav_seconds(data)
    except ValueError:
        return True
    return False


# the names the file list uses must match the spec
check(phyrebird.GRADES == GRADES, "GRADES has the 16 grades in order")
check(phyrebird.PLATES == PLATES, "PLATES has the 8 plate names")
check(phyrebird.EVAL_PARTS == PARTS, "EVAL_PARTS has the 9 parts")

expected = expected_pairs()
check(len(expected) == 82, "test list has 82 expected pairs")

# full tree: the 82 wanted paths plus the ones that must stay out, in reverse order
tree = [src for src, _ in expected] + OUTSIDE
tree.reverse()
result = phyrebird.evaluation_files(tree)
check(len(result) == 82, "full tree gives 82 pairs (got %d)" % len(result))
check(set(d for _, d in result) == set(d for _, d in expected), "destinations are the expected set")
check(set(result) == set(expected), "pairs are the expected ones")
check(not any(src in OUTSIDE for src, _ in result), "no excluded file is listed")
check(("Themes/Fiesta 2/Graphics/ScreenEvaluation/R_SS+.png", "R_SS+.png") in result, "R_SS+.png is listed")
check(("Themes/Fiesta 2/Sounds/Rank/RANK_A_B.mp3", "Rank/RANK_A_B.mp3") in result, "Rank/RANK_A_B.mp3 is listed")
check((BGM, "RESULT_BGM (loop).wav") in result, "RESULT_BGM (loop).wav is listed")
check(result == sorted(result, key=lambda p: p[1]), "list is sorted by destination")

check(phyrebird.evaluation_files(list(OUTSIDE)) == [], "only excluded files gives []")
check(phyrebird.evaluation_files([]) == [], "empty tree gives []")
check(len(phyrebird.evaluation_files([src for src, _ in expected if src != BGM])) == 81,
      "a missing file is left out, the rest stay")

check(abs(phyrebird.wav_seconds(make_wav()) - 2.0) < 1e-9, "wav_seconds of a 2 s WAV is 2.0")
check(abs(phyrebird.wav_seconds(with_odd_list_chunk(make_wav())) - 2.0) < 1e-9,
      "wav_seconds skips an odd-sized LIST chunk")
check(raises_value_error(b"not a wav"), "wav_seconds of non-WAV bytes raises ValueError")
wav = make_wav()
check(raises_value_error(wav[:wav.index(b"data")]), "wav_seconds without a data chunk raises ValueError")
check(raises_value_error(wav[:12] + wav[wav.index(b"data"):]), "wav_seconds without a fmt chunk raises ValueError")

check(phyrebird.evaluation_info(2.0) == "[Evaluation]\nBgmLength=2.000000\n", "evaluation_info text")

check(len(phyrebird.EVAL_LABELS) == 7, "EVAL_LABELS has the 7 table labels")
check(all(name in phyrebird.EVAL_PARTS for name in phyrebird.EVAL_LABELS), "every EVAL_LABELS name is in EVAL_PARTS")

# green_band: the blue band of the labels turns green, every other pixel stays as it is
band_in = [(0, 84, 255, 64), (3, 45, 131, 63), (71, 251, 252, 255), (192, 64, 255, 60), (0, 200, 40, 50)]
band_out = [(0, 255, 84, 64), (3, 131, 45, 63), (71, 251, 252, 255), (192, 64, 255, 60), (0, 200, 40, 50)]
src = Image.new("RGBA", (5, 1))
src.putdata(band_in)
dst = phyrebird.green_band(src)
check(dst.mode == "RGBA" and dst.size == (5, 1), "green_band gives an RGBA image of the same size")
check(list(dst.getdata()) == band_out, "green_band swaps blue and green only in the band pixels")
check(list(src.getdata()) == band_in, "green_band leaves its input image unchanged")

print("all passed" if failures == 0 else "%d failed" % failures)
sys.exit(1 if failures else 0)
