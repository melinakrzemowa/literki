## The board of best scores, newest entry highlighted.
extends Control

const MAIN_MENU := "res://src/scenes/main_menu.tscn"
const ROW_HEIGHT := 58


func _ready() -> void:
	var language := Settings.language
	var just_added := Scores.take_last_added()

	add_child(UiKit.backdrop())

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 22)
	add_child(column)

	column.add_child(UiKit.label(
		Texts.get_text("highscores", language), UiKit.HEADING_SIZE, UiKit.PRIMARY
	))

	if Scores.entries.is_empty():
		column.add_child(UiKit.label(
			Texts.get_text("no_scores", language), UiKit.BODY_SIZE, UiKit.INK_SOFT
		))
	else:
		column.add_child(_board(just_added))

	var back := UiKit.ghost_button(Texts.get_text("back", language), Vector2(240, 74))
	back.pressed.connect(func(): get_tree().change_scene_to_file(MAIN_MENU))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_child(back)
	column.add_child(footer)


func _board(just_added: Dictionary) -> Control:
	var centred := HBoxContainer.new()
	centred.alignment = BoxContainer.ALIGNMENT_CENTER

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel(UiKit.CARD, 28, 10))
	panel.custom_minimum_size = Vector2(620, 0)
	centred.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 26)
	panel.add_child(margin)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	margin.add_child(rows)

	for i in Scores.entries.size():
		rows.add_child(_row(i + 1, Scores.entries[i], _is_same(Scores.entries[i], just_added)))

	return centred


func _row(rank: int, entry: Dictionary, highlight: bool) -> Control:
	var colour := UiKit.PRIMARY if highlight else UiKit.INK
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	# A PanelContainer draws a dark default panel unless told otherwise, so
	# ordinary rows need an explicitly empty one.
	holder.add_theme_stylebox_override("panel",
		UiKit.panel(UiKit.BACKGROUND_DEEP, 14) if highlight else StyleBoxEmpty.new())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	holder.add_child(row)

	var place := UiKit.label("%d." % rank, UiKit.BODY_SIZE, UiKit.INK_SOFT)
	place.custom_minimum_size = Vector2(64, 0)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(place)

	var name_label := UiKit.label(str(entry.get("name", "")), UiKit.BODY_SIZE, colour)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var language := str(entry.get("language", ""))
	if WordBank.is_supported(language):
		var badge := UiKit.label(language.to_upper(), 20, UiKit.INK_SOFT)
		badge.custom_minimum_size = Vector2(54, 0)
		row.add_child(badge)

	var score := UiKit.label(str(entry.get("score", 0)), UiKit.BODY_SIZE, colour)
	score.custom_minimum_size = Vector2(90, 0)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(score)

	return holder


## Entries carry a timestamp, which is what makes two identical names and
## scores distinguishable.
func _is_same(entry: Dictionary, other: Dictionary) -> bool:
	if other.is_empty():
		return false
	return (
		entry.get("name", "") == other.get("name", "")
		and entry.get("score", null) == other.get("score", null)
		and entry.get("date", "") == other.get("date", "")
	)
