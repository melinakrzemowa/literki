## Speaks letters aloud through the operating system's own speech synthesiser
## (macOS Speech, Windows SAPI, speech-dispatcher on Linux), so the game ships
## no recorded audio and picks up whatever voices the machine already has.
##
## A few letters the voices read badly are shipped as small recordings instead
## (see tools/make_letter_sounds.py); those take precedence, and everything else
## goes to the synthesiser.
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

## Recordings that stand in for the synthesiser, as speech/<language>/<letter>.wav.
const CLIP_DIR := "res://assets/speech"
const CLIP_VOLUME_DB := 0.0  ## Nudge if the clips sit louder or quieter than the voice.

var _available := false
var _voice_by_language := {}
var _next_id := 1
var _player: AudioStreamPlayer
var _clip_utterance := -1


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = CLIP_VOLUME_DB
	_player.finished.connect(_on_clip_finished)
	add_child(_player)

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


## Speaks one letter, from a recording where we have one and the synthesiser
## otherwise. Returns an utterance id, or -1 if nothing was spoken — callers use
## the id to wait for [signal utterance_finished].
func speak_letter(character: String, language: String) -> int:
	var clip := _clip_for(character, language)
	if clip != null:
		return _play_clip(clip)
	return _speak(Letters.spoken_form(character), language, LETTER_RATE, true)


## True when this letter is spoken from a recording rather than synthesised.
func has_clip(character: String, language: String) -> bool:
	return _clip_for(character, language) != null


func _clip_for(character: String, language: String) -> AudioStream:
	var path := "%s/%s/%s.wav" % [CLIP_DIR, language, Letters.spoken_form(character)]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _play_clip(stream: AudioStream) -> int:
	stop()
	var id := _next_id
	_next_id += 1
	_clip_utterance = id
	_player.stream = stream
	_player.play()
	return id


## Stopping does not fire the player's own finished signal, so anything waiting
## on this utterance is released here instead of sitting out its timeout.
func _release_clip() -> void:
	if _clip_utterance < 0:
		return
	var id := _clip_utterance
	_clip_utterance = -1
	utterance_finished.emit.call_deferred(id)


func _on_clip_finished() -> void:
	_release_clip()


func speak_word(word: String, language: String) -> int:
	return _speak(word, language, WORD_RATE, true)


func stop() -> void:
	if _available:
		DisplayServer.tts_stop()
	if _player != null and _player.playing:
		_player.stop()
		_release_clip()


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
