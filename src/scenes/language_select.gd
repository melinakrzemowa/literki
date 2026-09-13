## The first screen: which language are we playing in?
##
## Deliberately wordless apart from the language names themselves — a child who
## cannot yet read still recognises "Polski" or hears it read aloud on hover.
extends Control

const MAIN_MENU := "res://src/scenes/main_menu.tscn"


func _ready() -> void:
	add_child(UiKit.backdrop())

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 28)
	add_child(column)

	column.add_child(UiKit.label("Literki", UiKit.TITLE_SIZE, UiKit.PRIMARY))

	# Shown in both languages at once, because we do not know yet which one the
	# child reads.
	var prompt := "%s  ·  %s" % [
		Texts.get_text("choose_language", WordBank.ENGLISH),
		Texts.get_text("choose_language", WordBank.POLISH),
	]
	column.add_child(UiKit.label(prompt, UiKit.BODY_SIZE, UiKit.INK_SOFT))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	column.add_child(spacer)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	column.add_child(row)

	var colours := [UiKit.BLUE, UiKit.PRIMARY]
	for i in WordBank.LANGUAGES.size():
		var language: String = WordBank.LANGUAGES[i]
		var button := UiKit.button(
			WordBank.LANGUAGE_NAMES[language], colours[i % colours.size()], Vector2(320, 140)
		)
		button.pressed.connect(_choose.bind(language))
		row.add_child(button)


func _choose(language: String) -> void:
	Settings.set_language(language)
	get_tree().change_scene_to_file(MAIN_MENU)
