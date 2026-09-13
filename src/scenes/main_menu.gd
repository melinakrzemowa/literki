## Play, look at the best scores, or change language.
extends Control

const GAME := "res://src/scenes/game.tscn"
const HIGHSCORES := "res://src/scenes/highscores.tscn"
const LANGUAGE_SELECT := "res://src/scenes/language_select.tscn"


func _ready() -> void:
	var language := Settings.language
	add_child(UiKit.backdrop())

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	add_child(column)

	column.add_child(UiKit.label(Texts.get_text("title", language), UiKit.TITLE_SIZE, UiKit.PRIMARY))
	column.add_child(UiKit.label(Texts.get_text("subtitle", language), UiKit.BODY_SIZE, UiKit.INK_SOFT))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 36)
	column.add_child(spacer)

	var buttons := VBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	column.add_child(buttons)

	_add(buttons, Texts.get_text("play", language), UiKit.PRIMARY, func(): _go(GAME))
	_add(buttons, Texts.get_text("highscores", language), UiKit.BLUE, func(): _go(HIGHSCORES))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 20)
	buttons.add_child(footer)

	var language_button := UiKit.ghost_button(
		"%s: %s" % [Texts.get_text("language", language), WordBank.LANGUAGE_NAMES[language]],
		Vector2(280, 74)
	)
	language_button.pressed.connect(func(): _go(LANGUAGE_SELECT))
	footer.add_child(language_button)

	var quit_button := UiKit.ghost_button(Texts.get_text("quit", language), Vector2(120, 74))
	quit_button.pressed.connect(func(): get_tree().quit())
	footer.add_child(quit_button)


func _add(parent: Control, text: String, colour: Color, action: Callable) -> void:
	var button := UiKit.button(text, colour)
	button.pressed.connect(action)
	parent.add_child(button)


func _go(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
