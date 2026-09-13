## The game's visual language: colours, panels and the big friendly buttons.
##
## Screens are built in code rather than laid out in the editor, so this is
## where the shared look lives — change a colour here and every screen follows.
class_name UiKit
extends RefCounted

const BACKGROUND := Color("fdf6e9")
const BACKGROUND_DEEP := Color("f7e6c9")
const INK := Color("4a3728")
const INK_SOFT := Color("9a8570")
const PRIMARY := Color("ff8a3d")
const PRIMARY_DEEP := Color("e06b22")
const CORRECT := Color("4fb477")
const WRONG := Color("e5574e")
const BLUE := Color("4d9de0")
const CARD := Color("ffffff")
const TILE_EMPTY := Color("ece0cc")

const TITLE_SIZE := 86
const HEADING_SIZE := 46
const BUTTON_SIZE := 38
const BODY_SIZE := 28


static func panel(fill: Color, radius: int = 24, shadow: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	if shadow > 0:
		style.shadow_color = Color(0.36, 0.26, 0.18, 0.18)
		style.shadow_size = shadow
		style.shadow_offset = Vector2(0, 4)
	return style


static func outlined_panel(fill: Color, border: Color, width: int = 5, radius: int = 24) -> StyleBoxFlat:
	var style := panel(fill, radius)
	style.set_border_width_all(width)
	style.border_color = border
	return style


static func label(text: String, size: int, colour: Color = INK) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", colour)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return node


## A chunky button a small child can hit without aiming.
static func button(text: String, fill: Color = PRIMARY, min_size := Vector2(420, 96)) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = min_size
	# Without this a vertical container stretches the button edge to edge.
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	node.focus_mode = Control.FOCUS_NONE
	node.add_theme_font_size_override("font_size", BUTTON_SIZE)
	node.add_theme_color_override("font_color", Color.WHITE)
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_color_override("font_pressed_color", Color.WHITE)

	var hover := fill.lightened(0.12)
	var pressed := fill.darkened(0.14)
	node.add_theme_stylebox_override("normal", panel(fill, 28, 8))
	node.add_theme_stylebox_override("hover", panel(hover, 28, 10))
	node.add_theme_stylebox_override("pressed", panel(pressed, 28, 2))
	node.add_theme_stylebox_override("disabled", panel(fill.lerp(BACKGROUND, 0.6), 28))
	return node


## A quieter button for "back" and other secondary actions.
static func ghost_button(text: String, min_size := Vector2(260, 74)) -> Button:
	var node := button(text, BACKGROUND_DEEP, min_size)
	node.add_theme_color_override("font_color", INK)
	node.add_theme_color_override("font_hover_color", INK)
	node.add_theme_color_override("font_pressed_color", INK)
	return node


## The soft cream backdrop every screen sits on.
static func backdrop() -> Control:
	var node := ColorRect.new()
	node.color = BACKGROUND
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Fills a Control with its parent, which is most of what these screens need.
static func fill(node: Control) -> Control:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	return node


## A quick scale pop, used whenever something good happens.
static func pop(node: Control, strength: float = 0.18, time: float = 0.22) -> void:
	if not is_instance_valid(node) or node.get_tree() == null:
		return
	node.pivot_offset = node.size * 0.5
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE * (1.0 + strength), time * 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, time * 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)


## A short left-right shake, used when something is wrong.
static func shake(node: Control, distance: float = 16.0, time: float = 0.3) -> void:
	if not is_instance_valid(node) or node.get_tree() == null:
		return
	var origin := node.position
	var tween := node.create_tween()
	for offset in [distance, -distance, distance * 0.6, -distance * 0.6, 0.0]:
		tween.tween_property(node, "position:x", origin.x + offset, time / 5.0)\
			.set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): node.position = origin)
