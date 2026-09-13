## The game screen: type a word letter by letter, hear it spelled back, then
## pick the picture it describes. Ten rounds, then a name and the score board.
##
## All the rules live in GameSession and RoundState; this file is only the
## staging — what moves, what is spoken, and when input is accepted.
extends Control

const MAIN_MENU := "res://src/scenes/main_menu.tscn"
const HIGHSCORES := "res://src/scenes/highscores.tscn"

const LETTER_FLIGHT := 0.40   ## How long a letter takes to fly to the top row.
const SPELL_GAP := 0.16       ## Breath between letters in the read-back.
const SPEECH_TIMEOUT := 1.8   ## Never wait longer than this on one letter.
const WORD_TIMEOUT := 3.0     ## Or on a whole word, which takes longer to say.
const CHEER_PAUSE := 0.35     ## Beat after the right picture, before the word.
const ROUND_BREAK := 0.6      ## And after the word, before the next round.

const BIG_LETTER_SIZE := Vector2(236, 280)

var _language: String
var _session: GameSession
var _round: RoundState = null

## Keys are ignored while letters are flying or the word is being read back,
## so a child hammering the keyboard cannot lose points to the animation.
var _input_locked := true

## Set when the player leaves. Animations and round changes are full of awaits
## that would otherwise resume inside a scene that is already on its way out.
var _leaving := false

## Set once the game-over card is up, so a late await cannot raise a second one.
var _finished := false

var _round_label: Label
var _score_label: Label
var _score_panel: PanelContainer
var _word_row: HBoxContainer
var _tiles: Array[LetterTile] = []
var _prompt: Label
var _stage: Control
var _big_letter: Panel
var _big_label: Label
var _picture_row: HBoxContainer
var _cards: Array[PictureCard] = []


func _ready() -> void:
	_language = Settings.language
	_session = GameSession.new(_language)
	_build()
	await get_tree().process_frame
	_next_round()


# ------------------------------------------------------------------ input ---

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_leave()
		return
	if _input_locked or _round == null or _round.phase != RoundState.Phase.TYPING:
		return

	var character := Letters.from_key(key.unicode)
	if not Letters.is_typable(character):
		return
	get_viewport().set_input_as_handled()
	_type(character)


func _type(character: String) -> void:
	var result := _round.type_letter(character)
	if not result["accepted"]:
		return
	_award(result["delta"])

	if result["delta"] < 0:
		_reject_letter()
		return

	_input_locked = true
	Speech.speak_letter(result["letter"], _language)
	await _fly_to_row(result["letter"], _tiles[_round.typed_count - 1])
	if _leaving or _round == null:
		return

	if result["word_complete"]:
		await _spell_back()
		if _leaving or _round == null:
			return
		_show_pictures()
	else:
		_show_letter(_round.current_letter())
		_input_locked = false


# ------------------------------------------------------------------ round ---

func _next_round() -> void:
	if _leaving:
		return
	_round = _session.start_next_round()
	if _round == null:
		_finish()
		return

	_clear_pictures()
	_build_word_row()
	_round_label.text = Texts.get_text("round_of", _language) % [
		_session.round_number, GameSession.ROUNDS_PER_GAME
	]
	_prompt.text = Texts.get_text("type_the_letter", _language)
	_show_letter(_round.current_letter())
	await get_tree().process_frame
	_input_locked = false


## Walks the finished word, lighting and speaking each letter in turn. The word
## itself is never spoken — reading it is the next thing we ask for.
func _spell_back() -> void:
	_prompt.text = Texts.get_text("well_done", _language)
	_hide_letter()
	await get_tree().create_timer(0.3).timeout

	for i in _tiles.size():
		if _leaving or _round == null or not is_instance_valid(_tiles[i]):
			return
		_tiles[i].set_highlighted(true)
		var utterance := Speech.speak_letter(_round.word[i], _language)
		await _wait_for_speech(utterance)
		_tiles[i].set_highlighted(false)
		await get_tree().create_timer(SPELL_GAP).timeout


func _show_pictures() -> void:
	_round.begin_picking()
	_prompt.text = Texts.get_text("which_one", _language)

	for i in _round.choices.size():
		var card := PictureCard.new(_round.choices[i])
		card.pressed.connect(_pick.bind(i))
		_picture_row.add_child(card)
		_cards.append(card)

	_picture_row.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(_picture_row, "modulate", Color.WHITE, 0.3)
	_input_locked = false


func _pick(index: int) -> void:
	var result := _round.pick(index)
	if not result["accepted"]:
		return

	if not result["correct"]:
		_cards[index].reject()
		return

	_award(result["delta"])
	for card in _cards:
		card.freeze()
	_cards[index].accept()
	_prompt.text = Texts.get_text("well_done", _language)
	_input_locked = true

	# Now the word gets said out loud. It was withheld through the typing and
	# the read-back so that choosing the picture had to come from reading it;
	# once that is done, hearing it is the reward and ties the two together.
	await get_tree().create_timer(CHEER_PAUSE).timeout
	if _leaving or _round == null:
		return
	await _wait_for_speech(Speech.speak_word(_round.word, _language), WORD_TIMEOUT)
	if _leaving or _round == null:
		return

	await get_tree().create_timer(ROUND_BREAK).timeout
	if _leaving or _round == null:
		return
	_next_round()


# ----------------------------------------------------------------- motion ---

## Sends a copy of the big letter up to its slot, then fills the slot in. The
## copy is parented to the screen rather than a container so nothing fights it
## over layout while it travels.
func _fly_to_row(character: String, tile: LetterTile) -> void:
	_big_label.add_theme_color_override("font_color", UiKit.CORRECT)
	UiKit.pop(_big_letter, 0.14, 0.16)
	await get_tree().create_timer(0.14).timeout
	if _leaving or not is_instance_valid(tile):
		return

	var ghost := _letter_label(character, UiKit.CORRECT, 186)
	ghost.size = _big_letter.size
	ghost.global_position = _big_letter.global_position
	ghost.pivot_offset = ghost.size * 0.5
	add_child(ghost)
	_hide_letter()

	var ratio := tile.size.y / _big_letter.size.y
	var destination := tile.global_position + tile.size * 0.5 - ghost.size * 0.5

	var tween := create_tween().set_parallel(true)
	tween.tween_property(ghost, "global_position", destination, LETTER_FLIGHT)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ghost, "scale", Vector2.ONE * ratio, LETTER_FLIGHT)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	ghost.queue_free()
	tile.reveal(character)


func _reject_letter() -> void:
	_big_label.add_theme_color_override("font_color", UiKit.WRONG)
	UiKit.shake(_big_letter)
	var tween := create_tween()
	tween.tween_interval(0.34)
	tween.tween_callback(func():
		if is_instance_valid(_big_label):
			_big_label.add_theme_color_override("font_color", UiKit.INK)
	)


## Waits for a spoken letter to finish, but never longer than SPEECH_TIMEOUT —
## a machine with no voices must not stall the read-back.
func _wait_for_speech(utterance: int, limit: float = SPEECH_TIMEOUT) -> void:
	if utterance < 0:
		await get_tree().create_timer(0.45).timeout
		return

	var finished := [false]
	var listener := func(id: int):
		if id == utterance:
			finished[0] = true
	Speech.utterance_finished.connect(listener)

	var deadline := Time.get_ticks_msec() + int(limit * 1000.0)
	while not finished[0] and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	Speech.utterance_finished.disconnect(listener)


# ------------------------------------------------------------------ score ---

func _award(delta: int) -> void:
	if delta == 0:
		return
	_score_label.text = str(_session.total_score())
	UiKit.pop(_score_panel, 0.16)
	_show_delta(delta)


## A small +1 or -1 drifting up from the score, so a change is never missed.
func _show_delta(delta: int) -> void:
	var text := "+%d" % delta if delta > 0 else str(delta)
	var colour := UiKit.CORRECT if delta > 0 else UiKit.WRONG
	var floater := UiKit.label(text, 40, colour)
	floater.size = Vector2(120, 50)
	floater.global_position = _score_panel.global_position + Vector2(-6, 56)
	add_child(floater)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(floater, "global_position:y", floater.global_position.y - 46, 0.7)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(floater, "modulate", Color(colour.r, colour.g, colour.b, 0), 0.7)\
		.set_delay(0.15)
	tween.chain().tween_callback(floater.queue_free)


# ------------------------------------------------------------------ screen ---

func _build() -> void:
	add_child(UiKit.backdrop())

	var page := MarginContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("margin_left", 40)
	page.add_theme_constant_override("margin_right", 40)
	page.add_theme_constant_override("margin_top", 24)
	page.add_theme_constant_override("margin_bottom", 30)
	add_child(page)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	page.add_child(column)

	column.add_child(_header())
	column.add_child(_word_area())

	_prompt = UiKit.label("", UiKit.BODY_SIZE, UiKit.INK_SOFT)
	_prompt.custom_minimum_size = Vector2(0, 52)
	column.add_child(_prompt)

	column.add_child(_stage_area())


func _header() -> Control:
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 78)
	bar.add_theme_constant_override("separation", 20)

	var menu := UiKit.ghost_button(Texts.get_text("menu", _language), Vector2(150, 62))
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(_leave)
	bar.add_child(menu)

	_round_label = UiKit.label("", UiKit.BODY_SIZE, UiKit.INK_SOFT)
	_round_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_round_label)

	_score_panel = PanelContainer.new()
	_score_panel.add_theme_stylebox_override("panel", UiKit.panel(UiKit.CARD, 22, 8))
	_score_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_score_panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 24)
	inner.add_theme_constant_override("margin_right", 24)
	inner.add_theme_constant_override("margin_top", 6)
	inner.add_theme_constant_override("margin_bottom", 6)
	_score_panel.add_child(inner)

	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 14)
	inner.add_child(score_row)
	score_row.add_child(UiKit.label(Texts.get_text("score", _language), 24, UiKit.INK_SOFT))

	_score_label = UiKit.label("0", 44, UiKit.PRIMARY)
	_score_label.custom_minimum_size = Vector2(64, 0)
	score_row.add_child(_score_label)

	return bar


func _word_area() -> Control:
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 140)
	_word_row = HBoxContainer.new()
	_word_row.add_theme_constant_override("separation", 14)
	holder.add_child(_word_row)
	return holder


func _stage_area() -> Control:
	_stage = Control.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.clip_contents = false

	_big_letter = Panel.new()
	_big_letter.add_theme_stylebox_override("panel", UiKit.panel(UiKit.CARD, 36, 14))
	_big_letter.anchor_left = 0.5
	_big_letter.anchor_top = 0.5
	_big_letter.anchor_right = 0.5
	_big_letter.anchor_bottom = 0.5
	_big_letter.offset_left = -BIG_LETTER_SIZE.x * 0.5
	_big_letter.offset_top = -BIG_LETTER_SIZE.y * 0.5
	_big_letter.offset_right = BIG_LETTER_SIZE.x * 0.5
	_big_letter.offset_bottom = BIG_LETTER_SIZE.y * 0.5
	_stage.add_child(_big_letter)

	_big_label = _letter_label("", UiKit.INK, 186)
	_big_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_big_letter.add_child(_big_label)

	var pictures := CenterContainer.new()
	pictures.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture_row = HBoxContainer.new()
	_picture_row.add_theme_constant_override("separation", 40)
	pictures.add_child(_picture_row)
	_stage.add_child(pictures)

	return _stage


func _letter_label(character: String, colour: Color, size: int) -> Label:
	var node := UiKit.label(character, size, colour)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Lays out one empty slot per letter, so the length of the word is visible
## before a single key is pressed.
func _build_word_row() -> void:
	for tile in _tiles:
		_word_row.remove_child(tile)
		tile.queue_free()
	_tiles.clear()

	for i in _round.word.length():
		var tile := LetterTile.new()
		_word_row.add_child(tile)
		_tiles.append(tile)


func _clear_pictures() -> void:
	for card in _cards:
		_picture_row.remove_child(card)
		card.queue_free()
	_cards.clear()
	_picture_row.modulate = Color.WHITE


func _show_letter(character: String) -> void:
	_big_label.text = character
	_big_label.add_theme_color_override("font_color", UiKit.INK)
	_big_letter.scale = Vector2.ONE
	_big_letter.modulate = Color.WHITE
	_big_letter.visible = true
	UiKit.pop(_big_letter, 0.12)


func _hide_letter() -> void:
	_big_letter.visible = false


# ------------------------------------------------------------- end of game ---

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_input_locked = true
	_round = null
	_hide_letter()
	_clear_pictures()
	_prompt.text = ""
	_round_label.text = ""

	var dim := ColorRect.new()
	dim.color = Color(0.29, 0.21, 0.14, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.panel(UiKit.BACKGROUND, 34, 18))
	centre.add_child(card)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 44)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(UiKit.label(Texts.get_text("game_over", _language), UiKit.HEADING_SIZE, UiKit.PRIMARY))
	column.add_child(UiKit.label(Texts.get_text("your_score", _language), UiKit.BODY_SIZE, UiKit.INK_SOFT))
	column.add_child(UiKit.label(str(_session.total_score()), 88, UiKit.INK))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	column.add_child(gap)

	column.add_child(UiKit.label(Texts.get_text("your_name", _language), UiKit.BODY_SIZE, UiKit.INK_SOFT))

	var name_input := LineEdit.new()
	name_input.max_length = HighscoreTable.MAX_NAME_LENGTH
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.custom_minimum_size = Vector2(420, 78)
	name_input.add_theme_font_size_override("font_size", 38)
	name_input.add_theme_color_override("font_color", UiKit.INK)
	name_input.add_theme_stylebox_override("normal", UiKit.outlined_panel(UiKit.CARD, UiKit.TILE_EMPTY, 4, 20))
	name_input.add_theme_stylebox_override("focus", UiKit.outlined_panel(UiKit.CARD, UiKit.PRIMARY, 4, 20))
	column.add_child(name_input)

	var button_gap := Control.new()
	button_gap.custom_minimum_size = Vector2(0, 8)
	column.add_child(button_gap)

	var save := UiKit.button(Texts.get_text("save", _language), UiKit.CORRECT, Vector2(420, 88))
	column.add_child(save)

	var saved := [false]
	var submit := func(_ignored = ""):
		if saved[0]:
			return
		saved[0] = true
		Scores.add(name_input.text, _session.total_score(), _language)
		get_tree().change_scene_to_file(HIGHSCORES)

	save.pressed.connect(submit)
	name_input.text_submitted.connect(submit)
	name_input.grab_focus()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	_input_locked = true
	_round = null
	Speech.stop()
	get_tree().change_scene_to_file(MAIN_MENU)
