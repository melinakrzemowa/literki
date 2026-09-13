extends RefCounted


func test_every_string_exists_in_every_language(t: TestHelper) -> void:
	for key in Texts.STRINGS:
		for language in WordBank.LANGUAGES:
			var value: String = Texts.STRINGS[key].get(language, "")
			t.check(not value.is_empty(), "'%s' has a %s translation" % [key, language])


func test_lookup_falls_back_to_english(t: TestHelper) -> void:
	t.equals(Texts.get_text("play", "en"), "Play", "English lookup")
	t.equals(Texts.get_text("play", "pl"), "Graj", "Polish lookup")
	t.equals(Texts.get_text("play", "de"), "Play", "an unknown language falls back to English")


func test_a_missing_key_returns_the_key(t: TestHelper) -> void:
	t.equals(Texts.get_text("nope", "en"), "nope", "a missing key is visible rather than blank")
