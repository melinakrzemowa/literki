## One slot in the word forming along the top of the screen.
##
## Every letter of the word gets a tile up front, empty, so a child can see how
## long the word is before they start. Tiles fill in as letters are typed.
class_name LetterTile
extends Panel

const SIZE := Vector2(104, 124)

var _label: Label


func _init() -> void:
	custom_minimum_size = SIZE
	add_theme_stylebox_override("panel", UiKit.outlined_panel(
		UiKit.TILE_EMPTY, UiKit.TILE_EMPTY.darkened(0.08), 4, 20
	))

	_label = UiKit.label("", 74, UiKit.INK)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


## Puts the letter in place with a small pop, once it has been typed.
func reveal(character: String) -> void:
	_label.text = character
	add_theme_stylebox_override("panel", UiKit.outlined_panel(
		UiKit.CARD, UiKit.CORRECT, 5, 20
	))
	UiKit.pop(self, 0.22)


## Lifts the tile while its letter is being read back at the end of the round.
func set_highlighted(on: bool) -> void:
	var fill := UiKit.CORRECT if on else UiKit.CARD
	var text := Color.WHITE if on else UiKit.INK
	add_theme_stylebox_override("panel", UiKit.outlined_panel(fill, UiKit.CORRECT, 5, 20))
	_label.add_theme_color_override("font_color", text)
	if on:
		UiKit.pop(self, 0.16)
