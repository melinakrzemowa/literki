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
var _index := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	await get_tree().process_frame
	_watchdog()
	await _run()
	print("TOUR: done, %d screenshots in %s" % [_index, _out])
	get_tree().quit()


## A stuck tour must never hold a window open forever.
func _watchdog() -> void:
	var timer := get_tree().create_timer(90.0)
	timer.timeout.connect(func():
		printerr("TOUR: watchdog fired after %d screenshots" % _index)
		get_tree().quit(2)
	)


func _run() -> void:
	print("TOUR: speech en=%s pl=%s" % [Speech.can_speak("en"), Speech.can_speak("pl")])

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
	await _wait(1.2)
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
