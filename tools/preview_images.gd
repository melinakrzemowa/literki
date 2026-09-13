## Renders every picture into one contact sheet, using the same SVG renderer
## the game uses, so art changes can be eyeballed without opening the editor.
##
##     godot --headless --script tools/preview_images.gd --quit -- out.png
extends SceneTree

const TILE := 128
const COLUMNS := 6


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "preview.png"

	var names := []
	for file in DirAccess.get_files_at("res://assets/images"):
		if file.ends_with(".svg"):
			names.append(file.get_basename())
	names.sort()

	var rows := int(ceil(float(names.size()) / COLUMNS))
	var sheet := Image.create_empty(COLUMNS * TILE, rows * TILE, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.12))

	var failed := 0
	for i in names.size():
		var source := FileAccess.get_file_as_string("res://assets/images/%s.svg" % names[i])
		var tile := Image.new()
		if tile.load_svg_from_string(source, float(TILE) / 256.0) != OK:
			push_error("could not render %s" % names[i])
			failed += 1
			continue
		tile.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(
			tile,
			Rect2i(0, 0, TILE, TILE),
			Vector2i((i % COLUMNS) * TILE, (i / COLUMNS) * TILE)
		)

	sheet.save_png(out_path)
	print("rendered %d pictures (%d failed) -> %s" % [names.size(), failed, out_path])
	print("order: ", ", ".join(names))
	quit(1 if failed > 0 else 0)
