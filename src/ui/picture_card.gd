## One of the three pictures a child chooses between.
##
## A wrong pick greys the card out and leaves it on screen rather than removing
## it, so the choice keeps narrowing visibly instead of jumping around.
class_name PictureCard
extends Button

const SIZE := Vector2(276, 276)

var concept_id: String

var _picture: TextureRect


func _init(p_concept_id: String) -> void:
	concept_id = p_concept_id
	custom_minimum_size = SIZE
	focus_mode = Control.FOCUS_NONE
	add_theme_stylebox_override("normal", UiKit.panel(UiKit.CARD, 30, 10))
	add_theme_stylebox_override("hover", UiKit.outlined_panel(UiKit.CARD, UiKit.PRIMARY, 6, 30))
	add_theme_stylebox_override("pressed", UiKit.panel(UiKit.BACKGROUND_DEEP, 30))
	add_theme_stylebox_override("disabled", UiKit.panel(UiKit.CARD, 30))

	_picture = TextureRect.new()
	_picture.texture = load(WordBank.image_path(concept_id))
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture.offset_left = 18
	_picture.offset_top = 18
	_picture.offset_right = -18
	_picture.offset_bottom = -18
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_picture)


## Fades the card back and stops it responding — this one was not the answer.
func reject() -> void:
	disabled = true
	UiKit.shake(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0.62, 0.60, 0.58, 0.5), 0.3)


## Marks the card as the right answer and quiets the other two.
func accept() -> void:
	disabled = true
	add_theme_stylebox_override("disabled", UiKit.outlined_panel(UiKit.CARD, UiKit.CORRECT, 10, 30))
	UiKit.pop(self, 0.12, 0.35)


## Stops a card being clicked without changing how it looks.
func freeze() -> void:
	disabled = true
