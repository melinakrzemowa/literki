# Literki

A typing and reading game for young children, in **English** and **Polish**.

Each round shows one big letter at a time. The child types it, hears it spoken
aloud, and watches it fly up to join the word forming along the top of the
screen. When the word is finished the game spells it back, letter by letter —
but never says the word itself. Then three pictures appear, and the child picks
the one the word describes. Reading it is the point.

Ten rounds make a game, and a good score goes on the highscore board.

## Requirements

- [Godot 4.6](https://godotengine.org/) or newer

Speech uses whatever synthesiser the operating system already provides —
macOS Speech, Windows SAPI, or `speech-dispatcher` on Linux — so there is no
audio to download. On a machine with no speech support the game still plays,
just silently.

## Running

```bash
godot --path .
```

## Tests

The game logic is kept separate from the scenes, so a whole game can be played
out without a window:

```bash
godot --headless --script tests/run_tests.gd --quit
```

## Pictures

The thirty pictures are generated, not hand-drawn, so they stay consistent:

```bash
python3 tools/generate_images.py
```

To look at them all at once:

```bash
godot --headless --script tools/preview_images.gd --quit -- /tmp/sheet.png
```

## Adding a language

Every picture is shared across languages, so a new language is a column of
words rather than a new set of drawings. Add the two-letter code to
`WordBank.LANGUAGES`, add its name to `LANGUAGE_NAMES`, and add a word for each
concept in `WordBank.CONCEPTS`. The tests will tell you if you missed one.

## Notes

Polish words are shown and spoken with their proper spelling, but the plain
ASCII letter is accepted too — a child on a US keyboard can type `slonce` for
`SŁOŃCE` and still see and hear it spelled correctly.
