## Walks the real screens, driving them with real input events, and saves a
## screenshot at each interesting moment.
##
##     godot --path . tools/tour.tscn -- /tmp/shots
##
## It lives as a child of the window root rather than as the current scene, so
## it survives the scene changes it triggers.
class_name TourDriver
extends Node

var _out := "/tmp/literki-shots"
var _mode := "shots"
var _index := 0
var _started := 0
var _failures: Array[String] = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1:
		_mode = args[1]
	DirAccess.make_dir_recursive_absolute(_out)
	await get_tree().process_frame
	# Screenshots come from RenderingServer.frame_post_draw, which stops firing
	# if the window ends up behind something and the compositor throttles it.
	# A tour that draws nothing waits forever, so keep the window in front.
	DisplayServer.window_move_to_foreground()

	# A net for a genuine hang, not a time budget: a whole screenshot tour runs
	# in about fifteen seconds.
	_watchdog(120.0 if _mode == "shots" else 600.0)
	_started = Time.get_ticks_msec()

	if _mode == "play":
		await _playthrough()
	else:
		await _run()
		print("TOUR: done, %d screenshots in %s" % [_index, _out])

	print("TOUR: took %.1fs" % ((Time.get_ticks_msec() - _started) / 1000.0))

	for failure in _failures:
		printerr("TOUR FAIL: ", failure)
	print("TOUR RESULT: ", "PASS" if _failures.is_empty() else "FAIL")
	get_tree().quit(0 if _failures.is_empty() else 1)


## A stuck tour must never hold a window open forever.
func _watchdog(seconds: float) -> void:
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(func():
		printerr("TOUR: watchdog fired after %ds and %d screenshots" % [int(seconds), _index])
		get_tree().quit(2)
	)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


## Plays all ten rounds through the real screen, typing Polish words with plain
## ASCII so the diacritic fallback is exercised end to end.
func _playthrough() -> void:
	Scores.clear()
	Settings.set_language(WordBank.POLISH)
	var game := await _goto("res://src/scenes/game.tscn")

	var expected := 0
	var seen := {}
	# The finished round stays in place while the word is read out, so waiting
	# for "a round exists" would keep finding the previous one.
	var previous: RoundState = null

	for index in GameSession.ROUNDS_PER_GAME:
		if not await _wait_until(
			func(): return game._round != null and game._round != previous, 20.0
		):
			_check(false, "round %d never started" % (index + 1))
			return
		previous = game._round

		var word: String = game._round.word
		_check(not seen.has(word), "round %d word %s is not a repeat" % [index + 1, word])
		seen[word] = true
		_check(
			game._session.round_number == index + 1,
			"round counter reads %d on round %d" % [game._session.round_number, index + 1]
		)

		for i in word.length():
			await _press(Letters.fold(word[i]))
			await _wait(0.6)
		expected += word.length()
		_check(
			game._round.typed_word() == word,
			"%s was fully typed with plain letters" % word
		)

		if not await _wait_until(
			func(): return game._round != null \
				and game._round.phase == RoundState.Phase.PICKING, 30.0
		):
			_check(false, "pictures never appeared in round %d" % (index + 1))
			return

		game._pick(game._round.correct_index())
		expected += Scoring.picture_points(0)
		_check(
			game._session.total_score() == expected,
			"score is %d after round %d, expected %d"
				% [game._session.total_score(), index + 1, expected]
		)
		await _wait(0.3)

	if not await _wait_until(func(): return game._round == null, 20.0):
		_check(false, "the game ended after ten rounds")
	_check(game._round == null, "the game ended after ten rounds")
	_check(game._session.is_finished(), "the session reports itself finished")
	print("TOUR: played %d words, final score %d" % [seen.size(), expected])

	for character in "Basia":
		await _press(character)
	await _wait(0.4)
	await _shot("playthrough-game-over")

	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ENTER
	Input.parse_input_event(event)
	await _wait(1.2)

	_check(Scores.entries.size() == 1, "one score was saved")
	if Scores.entries.size() == 1:
		_check(Scores.entries[0]["name"] == "Basia", "the typed name was saved")
		_check(Scores.entries[0]["score"] == expected, "the final score was saved")
		_check(Scores.entries[0]["language"] == WordBank.POLISH, "the language was saved")
	_check(
		get_tree().current_scene.scene_file_path.ends_with("highscores.tscn"),
		"saving goes to the score board"
	)
	await _shot("playthrough-board")


## Polls until the condition holds; false if it never did.
func _wait_until(condition: Callable, limit: float) -> bool:
	var waited := 0.0
	while waited < limit:
		if condition.call():
			return true
		await _wait(0.1)
		waited += 0.1
	return false


func _run() -> void:
	print("TOUR: speech en=%s pl=%s" % [Speech.can_speak("en"), Speech.can_speak("pl")])
	print("TOUR: pl 'Y' from a recording = %s" % Speech.has_clip("Y", WordBank.POLISH))

	Scores.clear()
	Settings.set_language(WordBank.ENGLISH)

	await _goto("res://src/scenes/language_select.tscn")
	await _shot("language-select")

	await _goto("res://src/scenes/main_menu.tscn")
	await _shot("main-menu-en")

	await _play_a_round()

	Settings.set_language(WordBank.POLISH)
	await _goto("res://src/scenes/main_menu.tscn")
	await _shot("main-menu-pl")

	await _goto("res://src/scenes/highscores.tscn")
	await _shot("highscores-empty")

	# A board with something on it, including the entry just added.
	Scores.add("Ola", 41, WordBank.POLISH)
	Scores.add("Kuba", 28, WordBank.ENGLISH)
	Scores.add("Zosia", 34, WordBank.POLISH)
	await _goto("res://src/scenes/highscores.tscn")
	await _shot("highscores-filled")


func _play_a_round() -> void:
	var game := await _goto("res://src/scenes/game.tscn")
	await _wait(0.6)
	var word: String = game._round.word
	print("TOUR: word is %s" % word)
	await _shot("game-first-letter")

	# A wrong key first, to catch the red flash and the -1.
	await _press("q" if not Letters.matches("q", word[0]) else "w")
	await _wait(0.25)
	await _shot("game-wrong-letter")
	await _wait(0.5)

	for i in word.length():
		await _press(word[i])
		await _wait(0.7)
		if i == 0:
			await _shot("game-letter-landed")

	# The word is complete; the read-back is running.
	await _wait(0.5)
	await _shot("game-spelling-back")

	var waited := 0.0
	while game._round != null and game._round.phase != RoundState.Phase.PICKING and waited < 25.0:
		await _wait(0.3)
		waited += 0.3
	await _wait(0.5)
	await _shot("game-pictures")

	var wrong := -1
	for i in game._round.choices.size():
		if i != game._round.correct_index():
			wrong = i
			break
	game._pick(wrong)
	await _wait(0.6)
	await _shot("game-picture-rejected")

	game._pick(game._round.correct_index())
	await _wait(0.6)
	await _shot("game-picture-correct")

	# Jump to the end so the game-over card can be seen without ten rounds.
	await _wait(2.5)
	game._session.round_number = GameSession.ROUNDS_PER_GAME
	game._finish()
	await _wait(0.6)
	await _shot("game-over")

	for character in "Ala":
		await _press(character)
	await _wait(0.4)
	await _shot("game-over-named")


func _goto(scene_path: String) -> Node:
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _wait(0.35)
	return get_tree().current_scene


func _press(character: String) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.unicode = character.unicode_at(0)
	Input.parse_input_event(event)
	await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	_index += 1
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%02d-%s.png" % [_out, _index, name])
