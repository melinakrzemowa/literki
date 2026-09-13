## Speaks letters aloud through the operating system's own speech synthesiser
## (macOS Speech, Windows SAPI, speech-dispatcher on Linux), so the game ships
## no recorded audio and picks up whatever voices the machine already has.
##
## Everything here degrades quietly: on a machine with no speech support the
## game still plays, just silently.
extends Node

## Emitted when a spoken phrase finishes or is cut off. The game uses this to
## pace the letter-by-letter read-back instead of guessing at timers.
signal utterance_finished(id: int)

## Voices to prefer when a language offers several, best first. Anything not
## listed falls back to the first voice the system reports for that language.
const PREFERRED_VOICES := {
	WordBank.ENGLISH: ["Samantha", "Daniel", "Karen"],
	WordBank.POLISH: ["Zosia"],
}

## A little slower than normal for single letters — they are the whole point.
const LETTER_RATE := 0.85
const WORD_RATE := 0.95
const VOLUME := 60
const PITCH := 1.1  ## Slightly bright, which reads as friendly to children.

var _available := false
var _voice_by_language := {}
var _next_id := 1


func _ready() -> void:
	_available = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
	if not _available:
		push_warning("Text-to-speech is unavailable; Literki will play silently.")
		return
	_resolve_voices()
	DisplayServer.tts_set_utterance_callback(
		DisplayServer.TTS_UTTERANCE_ENDED, _on_utterance_ended
	)
	DisplayServer.tts_set_utterance_callback(
		DisplayServer.TTS_UTTERANCE_CANCELED, _on_utterance_ended
	)


## True when this machine can actually say something in [param language].
func can_speak(language: String) -> bool:
	return _available and not str(_voice_by_language.get(language, "")).is_empty()


## Speaks one letter by name. Returns an utterance id, or -1 if nothing was
## spoken — callers use the id to wait for [signal utterance_finished].
func speak_letter(character: String, language: String) -> int:
	return _speak(character.to_upper(), language, LETTER_RATE, true)


func speak_word(word: String, language: String) -> int:
	return _speak(word, language, WORD_RATE, true)


func stop() -> void:
	if _available:
		DisplayServer.tts_stop()


func _speak(text: String, language: String, rate: float, interrupt: bool) -> int:
	if text.strip_edges().is_empty() or not can_speak(language):
		return -1
	var voice: String = _voice_by_language[language]
	var id := _next_id
	_next_id += 1
	DisplayServer.tts_speak(text, voice, VOLUME, PITCH, rate, id, interrupt)
	return id


func _resolve_voices() -> void:
	for language in WordBank.LANGUAGES:
		var ids := DisplayServer.tts_get_voices_for_language(language)
		if ids.is_empty():
			continue
		_voice_by_language[language] = _best_voice(language, ids)


## Matches preferred voices by display name, since voice ids differ per OS.
func _best_voice(language: String, ids: PackedStringArray) -> String:
	var names := {}
	for voice in DisplayServer.tts_get_voices():
		names[str(voice.get("id", ""))] = str(voice.get("name", ""))
	for wanted in PREFERRED_VOICES.get(language, []):
		for id in ids:
			if names.get(id, "") == wanted:
				return id
	return ids[0]


## May arrive on a non-main thread, so the signal is bounced to the main loop.
func _on_utterance_ended(id: int) -> void:
	utterance_finished.emit.call_deferred(id)
