extends RefCounted


func test_picture_points_drop_with_each_try(t: TestHelper) -> void:
	t.equals(Scoring.picture_points(0), 3, "first try is worth 3")
	t.equals(Scoring.picture_points(1), 2, "second try is worth 2")
	t.equals(Scoring.picture_points(2), 1, "third try is worth 1")


func test_picture_points_are_clamped_at_the_ends(t: TestHelper) -> void:
	t.equals(Scoring.picture_points(-1), 1, "a nonsense attempt index is worth the minimum")
	t.equals(Scoring.picture_points(99), 1, "beyond the last try is worth the minimum")


func test_letter_values(t: TestHelper) -> void:
	t.equals(Scoring.LETTER_CORRECT, 1, "a correct letter is worth 1")
	t.equals(Scoring.LETTER_WRONG, -1, "a wrong letter costs 1")
