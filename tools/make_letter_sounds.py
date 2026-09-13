#!/usr/bin/env python3
"""Cuts letter sounds out of the system voice, for letters it reads badly.

Run from the project root (macOS only — `say` and `afconvert` are Apple's):

    python3 tools/make_letter_sounds.py

Most letters need nothing: the system voices already read them by their proper
names, which `tools/check_voices.sh` demonstrates. A few do not, and cannot be
coaxed into it — Zosia reads a lone "y" as "igrek", and every dodge fails
because she spells out any isolated letter string ("yy" comes out as
"igrek igrek", byte for byte).

So the sound is taken from a real word instead. The word is synthesised with
the same voice the game uses, and the vowel is cut out of it, which keeps the
timbre identical to every other letter — something a downloaded recording of a
different speaker could not do.

The game prefers a clip here over the synthesiser, so adding a letter is a
matter of adding a line to SOURCES and re-running this.
"""

import array
import math
import pathlib
import subprocess
import sys
import tempfile
import wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "speech"

RATE = 22050
PEAK_TARGET = 18000  ## Roughly matches the synthesiser at the game's volume.
FADE_IN = 0.008
FADE_OUT = 0.030

## language -> letter -> (voice, word to carve it out of, what is wrong without it)
SOURCES = {
    "pl": {
        "y": ("Zosia", "ty", "a lone y is read as its name, 'igrek', which does not contain the sound"),
    },
}


def synthesise(voice: str, text: str, destination: pathlib.Path) -> None:
    aiff = destination.with_suffix(".aiff")
    subprocess.run(["say", "-v", voice, "-o", str(aiff), text], check=True)
    subprocess.run(
        ["afconvert", "-f", "WAVE", "-d", f"LEI16@{RATE}", "-c", "1", str(aiff), str(destination)],
        check=True, capture_output=True,
    )
    aiff.unlink()


def read_samples(path: pathlib.Path):
    with wave.open(str(path), "rb") as handle:
        samples = array.array("h")
        samples.frombytes(handle.readframes(handle.getnframes()))
        return samples, handle.getframerate()


def frame_energy(samples, rate: int, window: float = 0.005):
    step = int(rate * window)
    return [
        math.sqrt(sum(s * s for s in samples[i:i + step]) / step)
        for i in range(0, len(samples) - step, step)
    ], step


## Walks out from the loudest point: back to where the vowel begins, forward to
## where it has died away. Starting from the peak rather than the beginning is
## what skips the consonant in front of it.
def carve_vowel(samples, rate: int):
    energy, step = frame_energy(samples, rate)
    peak = max(energy)
    loudest = energy.index(peak)

    start = loudest
    while start > 0 and energy[start - 1] > 0.30 * peak:
        start -= 1
    end = loudest
    while end < len(energy) - 1 and energy[end + 1] > 0.06 * peak:
        end += 1

    return array.array("h", samples[start * step:min(len(samples), (end + 1) * step)])


def shape(clip, rate: int):
    fade_in = int(rate * FADE_IN)
    fade_out = int(rate * FADE_OUT)
    for i in range(min(fade_in, len(clip))):
        clip[i] = int(clip[i] * i / fade_in)
    for i in range(min(fade_out, len(clip))):
        clip[len(clip) - 1 - i] = int(clip[len(clip) - 1 - i] * i / fade_out)

    loudest = max(abs(s) for s in clip) or 1
    gain = min(4.0, PEAK_TARGET / loudest)
    return array.array("h", [max(-32768, min(32767, int(s * gain))) for s in clip])


def write(clip, rate: int, path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(rate)
        handle.writeframes(clip.tobytes())


def main() -> int:
    if sys.platform != "darwin":
        print("This needs macOS: `say` and `afconvert` are Apple's.")
        return 1

    with tempfile.TemporaryDirectory() as work:
        for language, letters in SOURCES.items():
            for letter, (voice, word, reason) in letters.items():
                source = pathlib.Path(work) / f"{language}_{letter}.wav"
                synthesise(voice, word, source)
                samples, rate = read_samples(source)
                clip = shape(carve_vowel(samples, rate), rate)
                destination = OUT / language / f"{letter}.wav"
                write(clip, rate, destination)
                print(
                    f"{language}/{letter}: {len(clip) / rate:.3f}s from {voice} saying "
                    f"\"{word}\" — {reason}"
                )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
