extends RefCounted


func test_every_concept_has_a_word_in_every_language(t: TestHelper) -> void:
	for concept in WordBank.CONCEPTS:
		for language in WordBank.LANGUAGES:
			var word := str(concept.get(language, ""))
			t.check(not word.is_empty(), "%s has a %s word" % [concept["id"], language])
			t.equals(word, word.to_upper(), "%s/%s is stored uppercase" % [concept["id"], language])


func test_concept_ids_are_unique(t: TestHelper) -> void:
	var seen := {}
	for concept in WordBank.CONCEPTS:
		var id: String = concept["id"]
		t.check(not seen.has(id), "concept id %s appears once" % id)
		seen[id] = true


func test_every_concept_has_a_picture_on_disk(t: TestHelper) -> void:
	for concept in WordBank.CONCEPTS:
		var path := WordBank.image_path(concept["id"])
		t.check(ResourceLoader.exists(path), "%s has a picture at %s" % [concept["id"], path])


func test_words_are_short_enough_for_a_child(t: TestHelper) -> void:
	for concept in WordBank.CONCEPTS:
		for language in WordBank.LANGUAGES:
			var word := str(concept[language])
			t.check(word.length() <= 7, "%s/%s is at most 7 letters" % [concept["id"], language])


func test_draw_round_returns_the_answer_among_distinct_choices(t: TestHelper) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in 50:
		var deal := WordBank.draw_round(rng)
		var choices: Array = deal["choices"]
		t.equals(choices.size(), WordBank.CHOICE_COUNT, "three pictures are offered")
		t.check(choices.has(deal["concept_id"]), "the correct picture is one of them")
		var unique := {}
		for choice in choices:
			unique[choice] = true
		t.equals(unique.size(), WordBank.CHOICE_COUNT, "no picture is shown twice")


func test_draw_round_avoids_excluded_concepts(t: TestHelper) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var exclude := ["dog", "cat", "fish"]
	for i in 50:
		var deal := WordBank.draw_round(rng, exclude)
		t.check(not exclude.has(deal["concept_id"]), "an excluded concept is not the answer")


func test_word_for_reads_the_right_column(t: TestHelper) -> void:
	t.equals(WordBank.word_for("dog", WordBank.ENGLISH), "DOG", "dog in English")
	t.equals(WordBank.word_for("dog", WordBank.POLISH), "PIES", "dog in Polish")
	t.equals(WordBank.word_for("nope", WordBank.ENGLISH), "", "an unknown concept has no word")


func test_language_support(t: TestHelper) -> void:
	t.check(WordBank.is_supported("en"), "English is supported")
	t.check(WordBank.is_supported("pl"), "Polish is supported")
	t.check(not WordBank.is_supported("de"), "German is not supported yet")


func test_the_bank_is_large_enough_for_a_full_game(t: TestHelper) -> void:
	t.check(
		WordBank.CONCEPTS.size() >= GameSession.ROUNDS_PER_GAME,
		"there are at least as many concepts as rounds, so nothing repeats"
	)
