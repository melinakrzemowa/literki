## Letter comparison helpers.
##
## Polish words contain diacritics (Ą, Ć, Ę, Ł, Ń, Ó, Ś, Ź, Ż) that are awkward
## to type on a non-Polish keyboard layout. The game still displays and speaks
## the properly spelled word, but accepts the plain ASCII base letter as a
## correct keystroke so a child is never stuck on a key they cannot reach.
class_name Letters
extends RefCounted

const FOLD := {
	"ą": "a", "ć": "c", "ę": "e", "ł": "l", "ń": "n",
	"ó": "o", "ś": "s", "ź": "z", "ż": "z",
}

## Lowercases a single character and strips its Polish diacritic, if any.
static func fold(character: String) -> String:
	var lowered := character.to_lower()
	return FOLD.get(lowered, lowered)


## True when the keystroke should count as typing the expected letter.
static func matches(typed: String, expected: String) -> bool:
	if typed.is_empty() or expected.is_empty():
		return false
	return fold(typed) == fold(expected)


## What to hand the speech synthesiser for a letter.
##
## Lowercase, always: given a single uppercase character the system voices
## announce the capitalisation — "capital P" in English, "duże P" in Polish —
## which is three times the audio and not what a child is being asked to hear.
## The screen still shows uppercase; only the spoken form changes.
static func spoken_form(character: String) -> String:
	return character.to_lower()


## True for keys that count as "typing a letter", right or wrong.
##
## A letter is recognised by having two distinct cases, which holds across
## every alphabet we might add later and excludes exactly the keys a child
## hits by accident: space, enter, digits and punctuation. Those are ignored
## rather than penalised.
static func is_typable(character: String) -> bool:
	if character.length() != 1:
		return false
	return character.to_lower() != character.to_upper()
