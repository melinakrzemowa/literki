extends RefCounted

## Speech is an autoload, which a --script run does not start; its path helpers
## are static, so the script itself is enough.
const Speech := preload("res://src/autoload/speech.gd")
const CLIP_DIR := "res://assets/speech"


func test_every_word_is_recorded(t: TestHelper) -> void:
	# Anything missing falls back to the synthesiser, which works but sounds
	# nothing like the rest. Re-run tools/record_speech.py after adding words.
	for language in WordBank.LANGUAGES:
		for id in WordBank.concept_ids():
			t.check(
				ResourceLoader.exists(Speech.word_clip_path(id, language)),
				"%s word for %s is recorded" % [language, id]
			)


func test_every_letter_in_every_word_is_recorded(t: TestHelper) -> void:
	for language in WordBank.LANGUAGES:
		for id in WordBank.concept_ids():
			for letter in WordBank.word_for(id, language):
				t.check(
					ResourceLoader.exists(Speech.letter_clip_path(letter, language)),
					"%s letter %s (in %s) is recorded" % [language, letter, id]
				)


func test_recordings_are_named_so_the_game_can_find_them(t: TestHelper) -> void:
	for language in DirAccess.get_directories_at(CLIP_DIR):
		t.check(WordBank.is_supported(language), "%s is a supported language" % language)
		t.equals(
			Array(DirAccess.get_directories_at("%s/%s" % [CLIP_DIR, language])),
			["letters", "words"],
			"%s holds letters and words" % language
		)
		for file in _clips("%s/%s/letters" % [CLIP_DIR, language]):
			var name := file.get_basename()
			t.check(
				_letter_names().has(name),
				"%s/letters/%s is named after a letter" % [language, file]
			)
		for file in _clips("%s/%s/words" % [CLIP_DIR, language]):
			t.check(
				WordBank.concept_ids().has(file.get_basename()),
				"%s/words/%s is named after a concept" % [language, file]
			)


func test_recordings_have_plain_ascii_names(t: TestHelper) -> void:
	for letter in Letters.CLIP_NAMES:
		var name: String = Letters.clip_name(letter)
		t.equals(name.to_ascii_buffer().get_string_from_ascii(), name, "%s is ASCII" % name)
		t.check(not name.contains("."), "%s has no dot in it" % name)
	t.equals(Letters.clip_name("Ł"), "l-stroke", "uppercase letters share the lowercase clip")
	t.equals(Letters.clip_name("B"), "b", "plain letters are named after themselves")


func _clips(directory: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(directory):
		if file.ends_with(".import"):
			continue
		found.append(file)
		assert(file.get_extension() == "wav", "%s/%s is not a wav" % [directory, file])
	return found


func _letter_names() -> Array[String]:
	var names: Array[String] = []
	for code in range(ord("a"), ord("z") + 1):
		names.append(char(code))
	names.append_array(Letters.CLIP_NAMES.values())
	return names
