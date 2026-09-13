## Headless test runner.
##
##     godot --headless --script tests/run_tests.gd --quit
##
## Exits non-zero when anything fails, so it can gate a commit.
extends SceneTree

const SUITES := {
	"Letters": preload("res://tests/test_letters.gd"),
	"WordBank": preload("res://tests/test_word_bank.gd"),
	"Scoring": preload("res://tests/test_scoring.gd"),
	"RoundState": preload("res://tests/test_round_state.gd"),
	"GameSession": preload("res://tests/test_game_session.gd"),
	"HighscoreTable": preload("res://tests/test_highscore_table.gd"),
}


func _init() -> void:
	var helper := TestHelper.new()
	var test_count := 0

	for suite_name in SUITES:
		var suite = SUITES[suite_name].new()
		for method in suite.get_method_list():
			if not str(method["name"]).begins_with("test_"):
				continue
			test_count += 1
			helper.start("%s.%s" % [suite_name, method["name"]])
			suite.call(method["name"], helper)

	print("")
	for failure in helper.failures:
		print("  FAIL  ", failure)
	print("%d tests, %d assertions, %d failed" % [test_count, helper.checks, helper.failures.size()])
	print("RESULT: ", "PASS" if helper.failures.is_empty() else "FAIL")
	quit(0 if helper.failures.is_empty() else 1)
