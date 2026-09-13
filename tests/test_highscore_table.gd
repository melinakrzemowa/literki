extends RefCounted


func _entry(name: String, score: int, date: String = "2026-01-01T00:00:00") -> Dictionary:
	return {"name": name, "score": score, "language": "en", "date": date}


func test_entries_sort_by_score_descending(t: TestHelper) -> void:
	var sorted := HighscoreTable.sorted([_entry("A", 5), _entry("B", 30), _entry("C", 12)])
	t.equals(sorted[0]["name"], "B", "the highest score is first")
	t.equals(sorted[1]["name"], "C", "then the middle")
	t.equals(sorted[2]["name"], "A", "then the lowest")


func test_ties_favour_whoever_got_there_first(t: TestHelper) -> void:
	var later := _entry("Later", 20, "2026-05-02T10:00:00")
	var earlier := _entry("Earlier", 20, "2026-05-01T10:00:00")
	var sorted := HighscoreTable.sorted([later, earlier])
	t.equals(sorted[0]["name"], "Earlier", "the earlier of two equal scores ranks higher")


func test_the_board_is_trimmed_to_ten(t: TestHelper) -> void:
	var entries := []
	for i in 12:
		entries = HighscoreTable.insert(entries, _entry("P%d" % i, i))
	t.equals(entries.size(), HighscoreTable.MAX_ENTRIES, "only ten entries are kept")
	t.equals(entries[0]["score"], 11, "the best score is kept")
	t.equals(entries[-1]["score"], 2, "the two worst were dropped")


func test_qualifying_for_the_board(t: TestHelper) -> void:
	t.check(HighscoreTable.qualifies([], 0), "any score makes an empty board")
	var full := []
	for i in HighscoreTable.MAX_ENTRIES:
		full = HighscoreTable.insert(full, _entry("P%d" % i, 10 + i))
	t.check(HighscoreTable.qualifies(full, 50), "a high score makes a full board")
	t.check(not HighscoreTable.qualifies(full, 3), "a low score does not")
	t.check(not HighscoreTable.qualifies(full, 10), "nor does tying the last place")


func test_names_are_trimmed_and_never_empty(t: TestHelper) -> void:
	t.equals(HighscoreTable.sanitize_name("  Ola  "), "Ola", "surrounding spaces are dropped")
	t.equals(HighscoreTable.sanitize_name(""), HighscoreTable.DEFAULT_NAME, "an empty name gets a placeholder")
	t.equals(HighscoreTable.sanitize_name("   "), HighscoreTable.DEFAULT_NAME, "so does a name of only spaces")
	t.equals(
		HighscoreTable.sanitize_name("ABCDEFGHIJKLMNOP").length(),
		HighscoreTable.MAX_NAME_LENGTH,
		"a very long name is cut to fit"
	)


func test_a_damaged_save_file_degrades_instead_of_breaking(t: TestHelper) -> void:
	t.equals(HighscoreTable.validate(null).size(), 0, "a missing file yields no scores")
	t.equals(HighscoreTable.validate("garbage").size(), 0, "a non-list yields no scores")
	t.equals(HighscoreTable.validate([1, "two", {}]).size(), 0, "malformed rows are dropped")
	var mixed := HighscoreTable.validate([{"name": "Ola", "score": 9}, {"score": 4}])
	t.equals(mixed.size(), 1, "the well-formed row survives")
	t.equals(mixed[0]["name"], "Ola", "with its name intact")


func test_validate_coerces_stored_types(t: TestHelper) -> void:
	var entries := HighscoreTable.validate([{"name": 42, "score": "17"}])
	t.equals(entries[0]["name"], "42", "a numeric name becomes text")
	t.equals(entries[0]["score"], 17, "a text score becomes a number")
