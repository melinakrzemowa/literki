#!/usr/bin/env python3
"""Records every letter and word the game says, with ElevenLabs voices.

Run from the project root with an ElevenLabs API key in the environment:

    ELEVENLABS_API_KEY=... python3 tools/record_speech.py

That records whatever is missing or out of date and leaves the rest alone,
so adding a word to WordBank and re-running this costs one short request.

    python3 tools/record_speech.py pl/letters/y en/words/dog   # redo these
    python3 tools/record_speech.py --force                     # redo all
    uv run --with praat-parselmouth python3 tools/record_speech.py --check --retake 6

Clips land in assets/speech/<language>/letters/<name>.wav and
assets/speech/<language>/words/<concept id>.wav, which is where the game looks
for them. Letter files use the ASCII names in LETTER_FILE_NAMES, matching
`Letters.clip_name` in src/core/letters.gd. What each clip was recorded from is
kept in tools/speech_manifest.json; a clip is re-recorded when its text, voice
or model changes.

--check is for whoever cannot listen to 160 clips: it plays each one after a
carrier phrase ("Litera …", "The word …") to ElevenLabs' own transcriber and
lists the ones it did not hear as intended. The carrier matters: on its own a
lone vowel or a three-letter word is too little for the transcriber to go on.
With --retake it records those again until one is heard right, since a voice
reads the same text a little differently every time. A lone vowel is measured
instead (see VOWELS), because the transcriber writes "E" for an e and a y
alike; that takes Praat, which is why --check runs under uv with parselmouth.

Stdlib only, like the other tools here, apart from Praat for --check.
"""

import argparse
import array
import concurrent.futures
import json
import os
import pathlib
import re
import statistics
import sys
import time
import unicodedata
import urllib.error
import urllib.request
import uuid
import wave

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "speech"
MANIFEST = ROOT / "tools" / "speech_manifest.json"
WORD_BANK = ROOT / "src" / "core" / "word_bank.gd"

API = "https://api.elevenlabs.io/v1"

## One native speaker per language: a soft, gentle woman's voice in each. A
## single voice for both would read one of them with an accent, which is the
## last thing a child learning to read needs to hear.
##
## language -> (voice id, name, model). Maria is a Polish speaker, but on
## eleven_v4 she sounded English to Polish ears, so Polish uses the model her
## voice was cloned on. That model has no language code and guesses from the
## text, which a three-letter word does not give it ("lis" came out as English
## "lace"), so it is handed a sentence of context in the right language.
## English stays on eleven_v4, which takes a language code and holds to it.
VOICES = {
    "en": ("AqDlTqiSASf1NfLfcjjM", "Luna - Children's Storyteller", "eleven_v4"),
    "pl": ("d4Z5Fvjohw3zxGpV8XUV", "Maria - Quiet and Gentle", "eleven_multilingual_v2"),
}

## Said to eleven_multilingual_v2 as what came before, but not recorded.
CONTEXT = {
    "en": "Listen carefully.",
    "pl": "Posłuchaj uważnie.",
}

## Starter accounts allow three requests at once.
CONCURRENCY = 3

RATE = 24000
PEAK_TARGET = 23000  ## About -3 dBFS, the same for every clip.
SILENCE = 0.02       ## Of the clip's peak; below this counts as silence.
LEAD = 0.02
TAIL = 0.06
FADE_IN = 0.005
FADE_OUT = 0.03

## language -> letter -> what to send the voice to have it say that letter.
##
## English capitals come out as their names, except Y, which the voice reads
## so like "I" that a listener cannot tell them apart; spelled "why" it is
## unmistakable. Polish ones are written out as the name, the way a teacher
## says them: "be", "ce", "eł". Two exceptions there: Y is its sound, because
## its name "igrek" does not contain it, and Ó is a plain "u" — it sounds
## exactly like U, and "u kreskowane" is a spelling lesson rather than a sound.
## The Y is written "Yyy.", the way Polish spells a hesitation: a lone "y"
## gets read as the Spanish word, which is "i", or set the voice babbling.
## E is a capital with a full stop, which lands on the right vowel more often
## than the bare letter; VOWELS below checks that it did.
LETTERS = {
    "en": {c: c.upper() for c in "abcdefghijklmnopqrstuvwxyz"} | {"y": "Why."},
    "pl": {
        "a": "a", "ą": "ą", "b": "be", "c": "ce", "ć": "cie", "d": "de",
        "e": "E.", "ę": "ę", "f": "ef", "g": "gie", "h": "ha", "i": "i",
        "j": "jot", "k": "ka", "l": "el", "ł": "eł", "m": "em", "n": "en",
        "ń": "eń", "o": "o", "ó": "u", "p": "pe", "r": "er", "s": "es",
        "ś": "eś", "t": "te", "u": "u", "w": "wu", "y": "Yyy.", "z": "zet",
        "ź": "ziet", "ż": "żet",
    },
}

## Where each Polish vowel has to land, as (F1 low, F1 high, F2 low, F2 high)
## in Hz, the first two resonances of the mouth that make one vowel sound like
## itself. The voice says a lone vowel differently every take: the same "e"
## came out as a proper e, an i, or a y, and the transcriber wrote "E" for all
## three. Measuring is what tells them apart. Maria's e inside the letter names
## (be, ce, el…) sits at F1 575–750, F2 1830–2290; the rest follow the same
## map of Polish vowels for a woman's voice.
##
## Ą and Ę are not measured. Said alone they end in a nasal glide, close to
## "oł" and "eł", which pulls their formants toward u. Takes that measured
## like a clean o and e sounded wrong to a Polish listener, and the ones that
## measured "off" were right, so the transcriber judges them instead.
VOWELS = {
    "pl": {
        "a": (750, 1100, 1300, 1800),
        "e": (550, 800, 1750, 2300),
        "i": (200, 450, 2400, 3200),
        "o": (450, 750, 800, 1250),
        "ó": (250, 450, 500, 1000),
        "u": (250, 450, 500, 1000),
        "y": (300, 500, 1600, 2100),
    },
}
MAX_VALLEY_DB = 10  ## A deeper dip mid-vowel means it was said twice.
MIN_VOWEL = 0.2     ## Seconds of voice; shorter sounds clipped next to the rest.

## ASCII file names for letters with a diacritic, after their Unicode names,
## so nothing depends on how a file system or an export stores "ł.wav".
LETTER_FILE_NAMES = {
    "ą": "a-ogonek", "ć": "c-acute", "ę": "e-ogonek", "ł": "l-stroke",
    "ń": "n-acute", "ó": "o-acute", "ś": "s-acute", "ź": "z-acute",
    "ż": "z-dot",
}

## Said before a clip when checking it, so the transcriber has context.
CARRIERS = {
    "letters": {"en": "The letter", "pl": "Litera"},
    "words": {"en": "The word", "pl": "Słowo"},
}


def api_key() -> str:
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key:
        raise SystemExit("Set ELEVENLABS_API_KEY to an ElevenLabs API key.")
    return key


def read_words() -> list:
    """The concepts from WordBank.CONCEPTS. Each line there is valid JSON."""
    concepts = []
    for line in WORD_BANK.read_text(encoding="utf-8").splitlines():
        line = line.strip().rstrip(",")
        if line.startswith('{"id"'):
            concepts.append(json.loads(line))
    if not concepts:
        raise SystemExit(f"Found no words in {WORD_BANK}.")
    return concepts


def clips() -> dict:
    """Every clip the game can ask for: name -> {language, kind, text, expect}."""
    wanted = {}
    for language, letters in LETTERS.items():
        for letter, text in letters.items():
            name = f"{language}/letters/{LETTER_FILE_NAMES.get(letter, letter)}"
            wanted[name] = {"language": language, "kind": "letters", "text": text,
                            "expect": [letter, text],
                            "vowel": VOWELS.get(language, {}).get(letter)}
    for concept in read_words():
        for language in LETTERS:
            word = concept[language]
            name = f"{language}/words/{concept['id']}"
            # Lowercase: "Sun." is how a calendar shortens Sunday, and that is
            # exactly what the voice said.
            wanted[name] = {"language": language, "kind": "words",
                            "text": word.lower() + ".", "expect": [word]}
    return wanted


def recipe(clip: dict) -> dict:
    """What a clip is recorded from; any change to it means recording again."""
    voice, _, model = VOICES[clip["language"]]
    return {"text": clip["text"], "voice": voice, "model": model}


# ------------------------------------------------------------------- API ---

def request(key: str, url: str, body: bytes, content_type: str) -> bytes:
    for attempt in range(8):
        req = urllib.request.Request(
            url, data=body, headers={"xi-api-key": key, "Content-Type": content_type}
        )
        try:
            with urllib.request.urlopen(req, timeout=90) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            # 429: over the concurrency limit. 409: the account is still
            # adding a library voice used for the first time.
            if error.code in (409, 429) and attempt < 7:
                time.sleep(1.5 * (attempt + 1))
                continue
            raise SystemExit(f"{error.code} from {url}: {error.read()[:300]!r}")
        except (urllib.error.URLError, TimeoutError, ConnectionError) as error:
            # A dropped connection or a failed DNS lookup is worth waiting out.
            if attempt < 7:
                time.sleep(1.5 * (attempt + 1))
                continue
            raise SystemExit(f"Could not reach {url}: {error}")
    raise AssertionError("unreachable")


def synthesise(key: str, text: str, language: str) -> array.array:
    voice, _, model = VOICES[language]
    body = {"text": text, "model_id": model}
    if model == "eleven_multilingual_v2":
        body["previous_text"] = CONTEXT[language]
    else:
        body["language_code"] = language
    pcm = request(key, f"{API}/text-to-speech/{voice}?output_format=pcm_{RATE}",
                  json.dumps(body).encode(), "application/json")
    samples = array.array("h")
    samples.frombytes(pcm[: len(pcm) // 2 * 2])
    return samples


def transcribe(key: str, path: pathlib.Path, language: str) -> str:
    boundary = uuid.uuid4().hex
    parts = []
    for name, value in (("model_id", "scribe_v2"), ("language_code", language)):
        parts.append(
            f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n'
            f"{value}\r\n".encode()
        )
    parts.append(
        f'--{boundary}\r\nContent-Disposition: form-data; name="file"; '
        f'filename="clip.wav"\r\nContent-Type: audio/wav\r\n\r\n'.encode()
        + path.read_bytes() + b"\r\n"
    )
    parts.append(f"--{boundary}--\r\n".encode())
    reply = request(key, f"{API}/speech-to-text", b"".join(parts),
                    f"multipart/form-data; boundary={boundary}")
    return json.loads(reply).get("text", "")


# ----------------------------------------------------------------- audio ---

## Cuts the silence the voice leaves either side, keeping a breath of it so
## nothing starts or stops abruptly. The game waits for a clip to finish before
## the next letter, so trailing silence would slow the read-back down.
def trim(samples: array.array) -> array.array:
    step = RATE // 100
    envelope = [max(abs(s) for s in samples[i:i + step]) or 0
                for i in range(0, len(samples), step)]
    peak = max(envelope) if envelope else 0
    if peak == 0:
        raise SystemExit("The voice returned silence.")
    loud = [i for i, level in enumerate(envelope) if level > SILENCE * peak]
    start = max(0, loud[0] * step - int(LEAD * RATE))
    end = min(len(samples), (loud[-1] + 1) * step + int(TAIL * RATE))
    return samples[start:end]


def shape(clip: array.array) -> array.array:
    fade_in = int(RATE * FADE_IN)
    fade_out = int(RATE * FADE_OUT)
    out = array.array("h", clip)
    for i in range(min(fade_in, len(out))):
        out[i] = int(out[i] * i / fade_in)
    for i in range(min(fade_out, len(out))):
        out[-1 - i] = int(out[-1 - i] * i / fade_out)
    gain = PEAK_TARGET / (max(abs(s) for s in out) or 1)
    return array.array("h", [max(-32768, min(32767, round(s * gain))) for s in out])


def write(samples: array.array, path: pathlib.Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(samples.tobytes())


def read(path: pathlib.Path) -> array.array:
    with wave.open(str(path), "rb") as handle:
        samples = array.array("h")
        samples.frombytes(handle.readframes(handle.getnframes()))
        return samples


# ----------------------------------------------------------------- check ---

def plain(text: str) -> str:
    """Lowercase letters and spaces only. Diacritics stay: ę is not e."""
    text = unicodedata.normalize("NFC", text.lower())
    return re.sub(r"[^\w ]|[\d_]", "", text).strip()


## What the transcriber writes for a clip that is right: homophones, ń spelled
## the Spanish way, and a lone ę, a nasal e it can only spell as the letter it
## sounds most like.
SOUNDS_LIKE = {
    "en": {"pear": ["pair"], "sun": ["son"]},
    "pl": {"but": ["butt"], "ń": ["ñ"], "ę": ["em", "en", "m", "n"]},
}


class Listener:
    """Plays clips to the transcriber after a carrier phrase."""

    def __init__(self, key: str, scratch: pathlib.Path):
        self.key = key
        self.scratch = scratch
        self.carriers = {}
        for kind, phrases in CARRIERS.items():
            for language, phrase in phrases.items():
                self.carriers[(kind, language)] = trim(synthesise(key, phrase + ",", language))
        self.gap = array.array("h", [0]) * int(0.15 * RATE)

    def hear(self, name: str, clip: dict, samples: array.array):
        """What was heard, and whether that is what was meant.

        A lone vowel is judged by measuring it instead: the transcriber cannot
        tell e from y. It only has to hear one short sound, not a babble.
        """
        audio = self.carriers[(clip["kind"], clip["language"])] + self.gap + samples
        probe = self.scratch / (name.replace("/", "_") + ".wav")
        write(audio, probe)
        heard = transcribe(self.key, probe, clip["language"])
        carrier = plain(CARRIERS[clip["kind"]][clip["language"]])
        rest = plain(heard)
        rest = rest[len(carrier):].strip() if rest.startswith(carrier) else rest

        if clip.get("vowel"):
            measured = measure_vowel(samples)
            if measured is None:
                return f"{heard!r}, no voice in it", False
            f1, f2, valley, voiced = measured
            lo1, hi1, lo2, hi2 = clip["vowel"]
            ok = (lo1 <= f1 <= hi1 and lo2 <= f2 <= hi2 and valley < MAX_VALLEY_DB
                  and MIN_VOWEL <= voiced and len(samples) / RATE < 0.9
                  and len(rest.split()) <= 1)
            return f"{heard!r}, F1 {f1} F2 {f2}, dip {valley} dB, {voiced:.2f}s voiced", ok

        meant = {plain(e) for e in clip["expect"]}
        meant |= set(SOUNDS_LIKE.get(clip["language"], {}).get(plain(clip["expect"][0]), []))
        return repr(heard), rest in meant


def measure_vowel(samples: array.array):
    """F1 and F2 over the middle of the voiced part, the deepest dip in
    loudness inside it, and how long it lasts. Uses Praat, through
    parselmouth; see the docstring."""
    import parselmouth

    sound = parselmouth.Sound([s / 32768 for s in samples], sampling_frequency=RATE)
    pitch = sound.to_pitch(time_step=0.01, pitch_floor=120, pitch_ceiling=500)
    voiced = [t for t, f in zip(pitch.xs(), pitch.selected_array["frequency"]) if f > 0]
    if len(voiced) < 3:
        return None
    start, end = voiced[0], voiced[-1]

    formant = sound.to_formant_burg(time_step=0.005, max_number_of_formants=5,
                                    maximum_formant=5500)
    f1s, f2s = [], []
    for i in range(41):
        t = start + (end - start) * (0.3 + 0.4 * i / 40)
        f1, f2 = formant.get_value_at_time(1, t), formant.get_value_at_time(2, t)
        if f1 == f1 and f2 == f2:  # Praat says NaN where it finds none
            f1s.append(f1)
            f2s.append(f2)
    if not f1s:
        return None

    intensity = sound.to_intensity(minimum_pitch=120, time_step=0.01)
    levels = [v for t, v in zip(intensity.xs(), intensity.values[0]) if start <= t <= end]
    top = max(levels)
    loud = [i for i, v in enumerate(levels) if v > top - 3]
    valley = top - min(levels[loud[0]:loud[-1] + 1])
    return (round(statistics.median(f1s)), round(statistics.median(f2s)),
            round(valley, 1), end - start)


def check(listener: Listener, wanted: dict, names: list) -> list:
    """Transcribes the recorded clips; returns the names that were misheard."""
    def one(name):
        return (name,) + listener.hear(name, wanted[name], read(OUT / f"{name}.wav"))

    doubtful = []
    with concurrent.futures.ThreadPoolExecutor(CONCURRENCY) as pool:
        for name, heard, ok in pool.map(one, names):
            if not ok:
                doubtful.append(name)
            print(f"{'ok ' if ok else '?? '} {name:24} {wanted[name]['text']!r:12} heard {heard}")
    print(f"{len(names) - len(doubtful)} heard as intended, {len(doubtful)} misheard.")
    return doubtful


## Takes vary from one request to the next, so a misheard clip usually only
## needs recording again. Keeps the first take that is heard as intended; if
## none is, the clip is left as it was, for a person to judge.
def retake(listener: Listener, wanted: dict, names: list, takes: int) -> list:
    def one(name):
        clip = wanted[name]
        for take in range(1, takes + 1):
            samples = shape(trim(synthesise(listener.key, clip["text"], clip["language"])))
            heard, ok = listener.hear(name, clip, samples)
            if ok:
                write(samples, OUT / f"{name}.wav")
                return name, f"take {take} heard as {heard}", True
        return name, f"still misheard after {takes} takes, last as {heard}", False

    stubborn = []
    with concurrent.futures.ThreadPoolExecutor(CONCURRENCY) as pool:
        for name, outcome, ok in pool.map(one, names):
            if not ok:
                stubborn.append(name)
            print(f"{'ok ' if ok else '?? '} {name:24} {outcome}")
    return stubborn


# ------------------------------------------------------------------ main ---

def save_manifest(manifest: dict) -> None:
    text = json.dumps(dict(sorted(manifest.items())), ensure_ascii=False, indent=1)
    MANIFEST.write_text(text + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("names", nargs="*", help="clips to re-record, e.g. pl/letters/y")
    parser.add_argument("--force", action="store_true", help="re-record every clip")
    parser.add_argument("--check", action="store_true",
                        help="transcribe the recorded clips instead of recording")
    parser.add_argument("--retake", type=int, metavar="TAKES", default=0,
                        help="with --check, record misheard clips again, up to TAKES times")
    args = parser.parse_args()

    key = api_key()
    wanted = clips()
    unknown = [n for n in args.names if n not in wanted]
    if unknown:
        raise SystemExit(f"No such clip: {', '.join(unknown)}")

    if args.check:
        names = args.names or sorted(wanted)
        missing = [n for n in names if not (OUT / f"{n}.wav").exists()]
        if missing:
            raise SystemExit(f"Not recorded yet: {', '.join(missing)}")
        scratch = pathlib.Path(os.environ.get("TMPDIR", "/tmp")) / "literki-speech-check"
        scratch.mkdir(parents=True, exist_ok=True)
        if any(wanted[n].get("vowel") for n in names):
            try:
                import parselmouth  # noqa: F401
            except ImportError:
                raise SystemExit("Checking vowels needs Praat: run this with "
                                 "`uv run --with praat-parselmouth python3 ...`.")
        listener = Listener(key, scratch)
        doubtful = check(listener, wanted, names)
        if doubtful and args.retake:
            print(f"Retaking {len(doubtful)}:")
            doubtful = retake(listener, wanted, doubtful, args.retake)
        if doubtful:
            print("Listen to these yourself: " + " ".join(doubtful))
        return 1 if doubtful else 0

    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    todo = [
        name for name in sorted(wanted)
        if args.force or name in args.names
        or manifest.get(name) != recipe(wanted[name])
        or not (OUT / f"{name}.wav").exists()
    ]

    def record(name):
        clip = wanted[name]
        samples = shape(trim(synthesise(key, clip["text"], clip["language"])))
        write(samples, OUT / f"{name}.wav")
        return name, len(samples) / RATE

    # Saved after every clip, so a run that dies halfway does not pay again
    # for what it already recorded.
    with concurrent.futures.ThreadPoolExecutor(CONCURRENCY) as pool:
        for name, seconds in pool.map(record, todo):
            manifest[name] = recipe(wanted[name])
            save_manifest(manifest)
            print(f"{name:24} {wanted[name]['text']!r:12} {seconds:.2f}s")

    # Clips for letters or words that no longer exist go too.
    for name in sorted(set(manifest) - set(wanted)):
        (OUT / f"{name}.wav").unlink(missing_ok=True)
        (OUT / f"{name}.wav.import").unlink(missing_ok=True)
        del manifest[name]
        print(f"{name:24} removed")

    save_manifest(manifest)
    characters = sum(len(wanted[n]["text"]) for n in todo)
    print(f"Recorded {len(todo)} of {len(wanted)} clips ({characters} characters).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
