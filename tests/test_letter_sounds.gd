extends RefCounted

const CLIP_DIR := "res://assets/speech"


func test_the_polish_y_is_played_from_a_recording(t: TestHelper) -> void:
	# Zosia reads a lone "y" as its name, "igrek", and cannot be talked out of
	# it, so this one letter comes from a clip instead. See
	# tools/make_letter_sounds.py.
	t.check(
		ResourceLoader.exists("%s/pl/y.wav" % CLIP_DIR),
		"there is a recording for the Polish y"
	)


func test_recordings_are_named_so_the_game_can_find_them(t: TestHelper) -> void:
	for language in DirAccess.get_directories_at(CLIP_DIR):
		t.check(WordBank.is_supported(language), "%s is a supported language" % language)
		for file in DirAccess.get_files_at("%s/%s" % [CLIP_DIR, language]):
			if file.ends_with(".import"):
				continue
			var letter := file.get_basename()
			t.equals(file.get_extension(), "wav", "%s/%s is a wav" % [language, file])
			t.check(
				Letters.is_typable(letter),
				"%s/%s is named after a single letter" % [language, file]
			)
			t.equals(
				letter, Letters.spoken_form(letter),
				"%s/%s is named the way the game looks it up" % [language, file]
			)
