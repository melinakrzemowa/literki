## Remembers the language chosen on the first screen, between sessions.
extends Node

const PATH := "user://settings.cfg"

signal language_changed(language: String)

var language: String = WordBank.ENGLISH:
	set = set_language


func _ready() -> void:
	_load()


func set_language(value: String) -> void:
	if not WordBank.is_supported(value) or value == language:
		return
	language = value
	_save()
	language_changed.emit(language)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	var stored := str(config.get_value("game", "language", WordBank.ENGLISH))
	if WordBank.is_supported(stored):
		language = stored


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "language", language)
	config.save(PATH)
