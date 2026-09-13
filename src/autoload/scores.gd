## Loads and saves the highscore board.
extends Node

const PATH := "user://highscores.json"

signal changed()

var entries: Array = []


func _ready() -> void:
	reload()


func reload() -> void:
	entries = []
	if not FileAccess.file_exists(PATH):
		return
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not read highscores: %s" % FileAccess.get_open_error())
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	entries = HighscoreTable.validate(parsed)


## True when this score would make the board, so the game knows whether to ask
## for a name.
func qualifies(score: int) -> bool:
	return HighscoreTable.qualifies(entries, score)


func add(player_name: String, score: int, language: String) -> void:
	var entry := {
		"name": HighscoreTable.sanitize_name(player_name),
		"score": score,
		"language": language,
		"date": Time.get_datetime_string_from_system(true),
	}
	entries = HighscoreTable.insert(entries, entry)
	_save()
	changed.emit()


func clear() -> void:
	entries = []
	_save()
	changed.emit()


func _save() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write highscores: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(entries, "\t"))
	file.close()
