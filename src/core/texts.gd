## Interface text in each supported language.
##
## Small enough that a dictionary beats Godot's translation machinery, and it
## keeps every string a translator needs in one readable block.
class_name Texts
extends RefCounted

const STRINGS := {
	"play": {"en": "Play", "pl": "Graj"},
	"highscores": {"en": "Best scores", "pl": "Najlepsze wyniki"},
	"quit": {"en": "Quit", "pl": "Wyjdź"},
	"back": {"en": "Back", "pl": "Wróć"},
	"menu": {"en": "Menu", "pl": "Menu"},
	"language": {"en": "Language", "pl": "Język"},
	"choose_language": {"en": "Choose a language", "pl": "Wybierz język"},
	"score": {"en": "Score", "pl": "Punkty"},
	"round_of": {"en": "Round %d of %d", "pl": "Runda %d z %d"},
	"type_the_letter": {"en": "Type this letter", "pl": "Napisz tę literę"},
	"which_one": {"en": "Which picture is it?", "pl": "Który obrazek to jest?"},
	"well_done": {"en": "Well done!", "pl": "Brawo!"},
	"game_over": {"en": "Great game!", "pl": "Świetna gra!"},
	"your_score": {"en": "Your score", "pl": "Twój wynik"},
	"your_name": {"en": "What is your name?", "pl": "Jak masz na imię?"},
	"save": {"en": "Save", "pl": "Zapisz"},
	"play_again": {"en": "Play again", "pl": "Zagraj jeszcze raz"},
	"no_scores": {"en": "No scores yet", "pl": "Jeszcze nie ma wyników"},
	"title": {"en": "Literki", "pl": "Literki"},
	"subtitle": {
		"en": "Type the letters, then find the picture",
		"pl": "Napisz litery, potem znajdź obrazek",
	},
}


static func get_text(key: String, language: String) -> String:
	var entry: Dictionary = STRINGS.get(key, {})
	if entry.is_empty():
		push_warning("Missing interface text for '%s'" % key)
		return key
	return entry.get(language, entry.get(WordBank.ENGLISH, key))
