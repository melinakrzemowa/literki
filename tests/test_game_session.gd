extends RefCounted


func _finish_round(round_state: RoundState, first_try: bool = true) -> void:
	for i in round_state.word.length():
		round_state.type_letter(round_state.current_letter())
	round_state.begin_picking()
	if not first_try:
		for i in round_state.choices.size():
			if i != round_state.correct_index():
				round_state.pick(i)
				break
	round_state.pick(round_state.correct_index())


func test_a_game_deals_exactly_ten_rounds(t: TestHelper) -> void:
	var session := GameSession.new(WordBank.ENGLISH, 42)
	var dealt := 0
	while true:
		var r := session.start_next_round()
		if r == null:
			break
		dealt += 1
		_finish_round(r)
	t.equals(dealt, GameSession.ROUNDS_PER_GAME, "ten rounds were dealt")
	t.check(session.is_finished(), "the session reports itself finished")


func test_no_word_repeats_within_a_game(t: TestHelper) -> void:
	var session := GameSession.new(WordBank.POLISH, 7)
	var seen := {}
	while true:
		var r := session.start_next_round()
		if r == null:
			break
		t.check(not seen.has(r.concept_id), "%s has not been used yet" % r.concept_id)
		seen[r.concept_id] = true
		_finish_round(r)


func test_the_total_includes_the_round_in_progress(t: TestHelper) -> void:
	var session := GameSession.new(WordBank.ENGLISH, 3)
	var r := session.start_next_round()
	t.equals(session.total_score(), 0, "a fresh round starts at zero")
	r.type_letter(r.current_letter())
	t.equals(session.total_score(), 1, "the corner total updates mid-round")
	r.type_letter("!")
	t.equals(session.total_score(), 1, "punctuation is not a letter and costs nothing")


func test_points_carry_across_rounds(t: TestHelper) -> void:
	var session := GameSession.new(WordBank.ENGLISH, 11)
	var first := session.start_next_round()
	_finish_round(first)
	var banked := session.total_score()
	t.check(banked > 0, "the first round scored something")
	var second := session.start_next_round()
	t.equals(session.total_score(), banked, "the total survives the round change")
	second.type_letter(second.current_letter())
	t.equals(session.total_score(), banked + 1, "and keeps growing")


func test_wrong_letters_can_push_the_total_below_zero(t: TestHelper) -> void:
	var session := GameSession.new(WordBank.ENGLISH, 5)
	var r := session.start_next_round()
	for i in 3:
		r.type_letter(_wrong_key(r.current_letter()))
	t.equals(session.total_score(), -3, "three wrong letters cost three points")


func test_the_same_seed_deals_the_same_game(t: TestHelper) -> void:
	var words_a := _play_out(GameSession.new(WordBank.ENGLISH, 2024))
	var words_b := _play_out(GameSession.new(WordBank.ENGLISH, 2024))
	var words_c := _play_out(GameSession.new(WordBank.ENGLISH, 2025))
	t.equals(words_a, words_b, "one seed always deals the same ten words")
	t.check(words_a != words_c, "a different seed deals a different game")


func test_the_word_matches_the_chosen_language(t: TestHelper) -> void:
	var session := GameSession.new(WordBank.POLISH, 88)
	var r := session.start_next_round()
	t.equals(r.word, WordBank.word_for(r.concept_id, WordBank.POLISH), "Polish session deals Polish words")


func _play_out(session: GameSession) -> Array:
	var words := []
	while true:
		var r := session.start_next_round()
		if r == null:
			break
		words.append(r.word)
		_finish_round(r)
	return words


func _wrong_key(expected: String) -> String:
	return "q" if not Letters.matches("q", expected) else "w"
