extends RefCounted


func _dog_round() -> RoundState:
	var choices: Array[String] = ["cat", "dog", "bird"]
	return RoundState.new("dog", "DOG", choices)


func _type(round_state: RoundState, keys: String) -> void:
	for i in keys.length():
		round_state.type_letter(keys[i])


func test_a_correct_letter_advances_and_scores(t: TestHelper) -> void:
	var r := _dog_round()
	var result := r.type_letter("d")
	t.check(result["accepted"], "the keystroke was handled")
	t.equals(result["delta"], 1, "a correct letter is worth 1")
	t.equals(r.typed_count, 1, "the word advanced by one letter")
	t.equals(r.typed_word(), "D", "the top row shows the letter typed so far")
	t.equals(r.current_letter(), "O", "the next letter is now being asked for")


func test_a_wrong_letter_costs_a_point_and_does_not_advance(t: TestHelper) -> void:
	var r := _dog_round()
	var result := r.type_letter("x")
	t.equals(result["delta"], -1, "a wrong letter costs 1")
	t.equals(r.typed_count, 0, "the word did not advance")
	t.equals(r.current_letter(), "D", "the same letter is still being asked for")
	t.equals(r.score, -1, "the round score went down")


func test_finishing_the_word_moves_to_the_read_back(t: TestHelper) -> void:
	var r := _dog_round()
	_type(r, "do")
	t.equals(r.phase, RoundState.Phase.TYPING, "still typing with one letter to go")
	var result := r.type_letter("g")
	t.check(result["word_complete"], "the last letter completed the word")
	t.equals(r.phase, RoundState.Phase.SPELLING, "the word is now read back")
	t.equals(r.score, 3, "three correct letters are worth three points")
	t.equals(r.typed_word(), "DOG", "the whole word is on the top row")


func test_keystrokes_during_the_read_back_are_ignored(t: TestHelper) -> void:
	var r := _dog_round()
	_type(r, "dog")
	var result := r.type_letter("x")
	t.check(not result["accepted"], "a stray key during the read-back is ignored")
	t.equals(result["delta"], 0, "and costs nothing")
	t.equals(r.score, 3, "the score is untouched")


func test_picking_the_right_picture_first_try_scores_three(t: TestHelper) -> void:
	var r := _dog_round()
	_type(r, "dog")
	r.begin_picking()
	t.equals(r.phase, RoundState.Phase.PICKING, "the pictures are up")
	var result := r.pick(r.correct_index())
	t.check(result["correct"], "the right picture was chosen")
	t.equals(result["delta"], 3, "first try is worth 3")
	t.equals(r.phase, RoundState.Phase.DONE, "the round is over")
	t.equals(r.score, 6, "three letters plus three picture points")


func test_a_wrong_picture_greys_out_and_keeps_the_round_going(t: TestHelper) -> void:
	var r := _dog_round()
	_type(r, "dog")
	r.begin_picking()
	var wrong := 0 if r.correct_index() != 0 else 1
	var result := r.pick(wrong)
	t.check(not result["correct"], "the wrong picture was rejected")
	t.equals(result["delta"], 0, "a wrong picture costs nothing")
	t.check(r.rejected.has(wrong), "the wrong picture is greyed out")
	t.equals(r.phase, RoundState.Phase.PICKING, "the child keeps choosing")


func test_second_and_third_tries_score_less(t: TestHelper) -> void:
	var second := _dog_round()
	_type(second, "dog")
	second.begin_picking()
	second.pick(_first_wrong(second))
	t.equals(second.pick(second.correct_index())["delta"], 2, "second try is worth 2")

	var third := _dog_round()
	_type(third, "dog")
	third.begin_picking()
	third.pick(_first_wrong(third))
	third.pick(_first_wrong(third))
	t.equals(third.pick(third.correct_index())["delta"], 1, "third try is worth 1")


func test_clicking_an_already_rejected_picture_does_nothing(t: TestHelper) -> void:
	var r := _dog_round()
	_type(r, "dog")
	r.begin_picking()
	var wrong := _first_wrong(r)
	r.pick(wrong)
	var again := r.pick(wrong)
	t.check(not again["accepted"], "a greyed-out picture cannot be clicked again")
	t.equals(r.rejected.size(), 1, "and it is not counted as a second try")


func test_picking_before_the_word_is_typed_is_ignored(t: TestHelper) -> void:
	var r := _dog_round()
	var result := r.pick(r.correct_index())
	t.check(not result["accepted"], "pictures cannot be picked while still typing")
	t.equals(r.score, 0, "and award nothing")


func test_out_of_range_picks_are_ignored(t: TestHelper) -> void:
	var r := _dog_round()
	_type(r, "dog")
	r.begin_picking()
	t.check(not r.pick(-1)["accepted"], "a negative index is ignored")
	t.check(not r.pick(99)["accepted"], "an index past the end is ignored")


func test_a_polish_word_can_be_typed_without_diacritics(t: TestHelper) -> void:
	var choices: Array[String] = ["sun", "cat", "dog"]
	var r := RoundState.new("sun", "SŁOŃCE", choices)
	_type(r, "slonce")
	t.equals(r.phase, RoundState.Phase.SPELLING, "plain letters finished the word")
	t.equals(r.score, 6, "all six letters counted")
	t.equals(r.typed_word(), "SŁOŃCE", "the top row still shows the correct spelling")


func _first_wrong(round_state: RoundState) -> int:
	for i in round_state.choices.size():
		if i != round_state.correct_index() and not round_state.rejected.has(i):
			return i
	return -1
