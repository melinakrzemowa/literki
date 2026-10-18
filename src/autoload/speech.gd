## Says letters and words aloud.
##
## Everything the game says is a recording, made with ElevenLabs by
## tools/record_speech.py: a native speaker per language, the same on every
## machine and in every browser. A letter or word without one — a word just
## added to WordBank, say — falls back to the operating system's synthesiser
## (macOS Speech, Windows SAPI, speech-dispatcher on Linux, speechSynthesis in
## a browser), so nothing goes unsaid while it waits to be recorded.
##
## Everything here degrades quietly: with neither a recording nor a voice, the
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

## Recordings, as <language>/letters/<Letters.clip_name>.wav and
## <language>/words/<concept id>.wav.
const CLIP_DIR := "res://assets/speech"
const CLIP_VOLUME_DB := 0.0

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
		push_warning("Text-to-speech is unavailable; only recorded speech will play.")
		return
	_resolve_voices()
	DisplayServer.tts_set_utterance_callback(
		DisplayServer.TTS_UTTERANCE_ENDED, _on_utterance_ended
	)
	DisplayServer.tts_set_utterance_callback(
		DisplayServer.TTS_UTTERANCE_CANCELED, _on_utterance_ended
	)


## True when the synthesiser — the fallback for anything not recorded — can say
## something in [param language] on this machine.
func can_speak(language: String) -> bool:
	return _available and not _voice_for(language).is_empty()


## Speaks one letter, from its recording where there is one and the
## synthesiser otherwise. Returns an utterance id, or -1 if nothing was spoken —
## callers use the id to wait for [signal utterance_finished].
func speak_letter(character: String, language: String) -> int:
	var clip := _load_clip(letter_clip_path(character, language))
	if clip != null:
		return _play_clip(clip)
	return _speak(Letters.spoken_form(character), language, LETTER_RATE, true)


## Speaks the word for a concept, the same way.
func speak_word(concept_id: String, language: String) -> int:
	var clip := _load_clip(word_clip_path(concept_id, language))
	if clip != null:
		return _play_clip(clip)
	return _speak(WordBank.word_for(concept_id, language), language, WORD_RATE, true)


static func letter_clip_path(character: String, language: String) -> String:
	return "%s/%s/letters/%s.wav" % [CLIP_DIR, language, Letters.clip_name(character)]


static func word_clip_path(concept_id: String, language: String) -> String:
	return "%s/%s/words/%s.wav" % [CLIP_DIR, language, concept_id]


func _load_clip(path: String) -> AudioStream:
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


func stop() -> void:
	if _available:
		DisplayServer.tts_stop()
	if _player != null and _player.playing:
		_player.stop()
		_release_clip()


func _speak(text: String, language: String, rate: float, interrupt: bool) -> int:
	var voice := _voice_for(language)
	if text.strip_edges().is_empty() or not _available or voice.is_empty():
		return -1
	var id := _next_id
	_next_id += 1
	DisplayServer.tts_speak(text, voice, VOLUME, PITCH, rate, id, interrupt)
	return id


## Finds the voice for a language, remembering it once found.
##
## Resolved on use rather than once at startup: browsers fill in the voice list
## asynchronously, so on the web it is still empty when the game boots. Looking
## it up once there meant the game came up permanently silent.
func _voice_for(language: String) -> String:
	if not _available:
		return ""
	var cached := str(_voice_by_language.get(language, ""))
	if not cached.is_empty():
		return cached

	var ids := DisplayServer.tts_get_voices_for_language(language)
	if ids.is_empty():
		return ""
	var best := _best_voice(language, ids)
	_voice_by_language[language] = best
	return best


func _resolve_voices() -> void:
	for language in WordBank.LANGUAGES:
		_voice_for(language)


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
