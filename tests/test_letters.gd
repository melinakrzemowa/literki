extends RefCounted


func test_matches_are_case_insensitive(t: TestHelper) -> void:
	t.check(Letters.matches("a", "A"), "lowercase key matches uppercase letter")
	t.check(Letters.matches("A", "A"), "uppercase key matches uppercase letter")
	t.check(not Letters.matches("b", "A"), "a different letter does not match")


func test_polish_diacritics_accept_the_base_letter(t: TestHelper) -> void:
	t.check(Letters.matches("l", "Ł"), "L stands in for Ł")
	t.check(Letters.matches("a", "Ą"), "A stands in for Ą")
	t.check(Letters.matches("e", "Ę"), "E stands in for Ę")
	t.check(Letters.matches("z", "Ż"), "Z stands in for Ż")
	t.check(Letters.matches("z", "Ź"), "Z stands in for Ź")
	t.check(Letters.matches("o", "Ó"), "O stands in for Ó")
	t.check(Letters.matches("n", "Ń"), "N stands in for Ń")
	t.check(Letters.matches("s", "Ś"), "S stands in for Ś")
	t.check(Letters.matches("c", "Ć"), "C stands in for Ć")


func test_the_real_diacritic_still_matches(t: TestHelper) -> void:
	t.check(Letters.matches("ł", "Ł"), "typing the actual Ł matches")
	t.check(Letters.matches("Ż", "Ż"), "typing the actual Ż matches")


func test_folding_does_not_collapse_unrelated_letters(t: TestHelper) -> void:
	t.check(not Letters.matches("s", "Z"), "S does not match Z")
	t.check(not Letters.matches("l", "T"), "L does not match T")


func test_empty_input_never_matches(t: TestHelper) -> void:
	t.check(not Letters.matches("", "A"), "no keystroke is not a match")
	t.check(not Letters.matches("a", ""), "nothing expected is not a match")


func test_letters_are_spoken_without_announcing_the_capital(t: TestHelper) -> void:
	# An uppercase character makes the system voices say "capital P" / "duże P".
	t.equals(Letters.spoken_form("P"), "p", "an uppercase letter is spoken lowercase")
	t.equals(Letters.spoken_form("p"), "p", "a lowercase letter is left alone")
	t.equals(Letters.spoken_form("Ł"), "ł", "a Polish letter keeps its diacritic")
	t.equals(Letters.spoken_form("Ó"), "ó", "and so does O with an accent")


func test_keys_without_a_character_produce_nothing(t: TestHelper) -> void:
	# Arrows, shift and friends report zero. char(0) would make a string
	# holding a NUL, which Godot logs a Unicode parsing error for.
	t.equals(Letters.from_key(0), "", "a key with no character gives nothing")
	t.equals(Letters.from_key(13), "", "enter gives nothing")
	t.equals(Letters.from_key(27), "", "escape gives nothing")
	t.equals(Letters.from_key(32), " ", "space still comes through, to be ignored later")
	t.equals(Letters.from_key(65), "A", "a letter key gives its letter")
	t.equals(Letters.from_key("ł".unicode_at(0)), "ł", "so does a Polish letter key")


func test_letter_keys_are_recognised(t: TestHelper) -> void:
	t.check(Letters.is_typable("a"), "a letter is a letter key")
	t.check(Letters.is_typable("Z"), "an uppercase letter is a letter key")
	t.check(Letters.is_typable("ł"), "a Polish letter is a letter key")
	t.check(Letters.is_typable("Ż"), "an uppercase Polish letter is a letter key")


func test_stray_keys_are_ignored_rather_than_penalised(t: TestHelper) -> void:
	t.check(not Letters.is_typable(" "), "space is not a letter key")
	t.check(not Letters.is_typable("5"), "a digit is not a letter key")
	t.check(not Letters.is_typable("!"), "punctuation is not a letter key")
	t.check(not Letters.is_typable("-"), "a dash is not a letter key")
	t.check(not Letters.is_typable(""), "no character is not a letter key")
	t.check(not Letters.is_typable("ab"), "two characters are not one keystroke")
