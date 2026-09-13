## The vocabulary the game draws from.
##
## Each entry is a "concept": one picture shared by every language, plus the
## word for that picture in each supported language. Sharing the picture means
## a new language only needs a column of words, never a new set of drawings.
class_name WordBank
extends RefCounted

const ENGLISH := "en"
const POLISH := "pl"

const LANGUAGES := [ENGLISH, POLISH]

## Human-readable language names, shown on the language picker.
const LANGUAGE_NAMES := {
	ENGLISH: "English",
	POLISH: "Polski",
}

## Words are stored uppercase because that is how they are shown and typed.
const CONCEPTS := [
	{"id": "dog", "en": "DOG", "pl": "PIES"},
	{"id": "cat", "en": "CAT", "pl": "KOT"},
	{"id": "fish", "en": "FISH", "pl": "RYBA"},
	{"id": "bird", "en": "BIRD", "pl": "PTAK"},
	{"id": "cow", "en": "COW", "pl": "KROWA"},
	{"id": "frog", "en": "FROG", "pl": "ŻABA"},
	{"id": "duck", "en": "DUCK", "pl": "KACZKA"},
	{"id": "mouse", "en": "MOUSE", "pl": "MYSZ"},
	{"id": "lion", "en": "LION", "pl": "LEW"},
	{"id": "sun", "en": "SUN", "pl": "SŁOŃCE"},
	{"id": "moon", "en": "MOON", "pl": "KSIĘŻYC"},
	{"id": "star", "en": "STAR", "pl": "GWIAZDA"},
	{"id": "cloud", "en": "CLOUD", "pl": "CHMURA"},
	{"id": "tree", "en": "TREE", "pl": "DRZEWO"},
	{"id": "flower", "en": "FLOWER", "pl": "KWIAT"},
	{"id": "house", "en": "HOUSE", "pl": "DOM"},
	{"id": "car", "en": "CAR", "pl": "AUTO"},
	{"id": "boat", "en": "BOAT", "pl": "ŁÓDKA"},
	{"id": "ball", "en": "BALL", "pl": "PIŁKA"},
	{"id": "apple", "en": "APPLE", "pl": "JABŁKO"},
	{"id": "banana", "en": "BANANA", "pl": "BANAN"},
	{"id": "cake", "en": "CAKE", "pl": "TORT"},
	{"id": "milk", "en": "MILK", "pl": "MLEKO"},
	{"id": "egg", "en": "EGG", "pl": "JAJKO"},
	{"id": "heart", "en": "HEART", "pl": "SERCE"},
	{"id": "key", "en": "KEY", "pl": "KLUCZ"},
	{"id": "book", "en": "BOOK", "pl": "KSIĄŻKA"},
	{"id": "shoe", "en": "SHOE", "pl": "BUT"},
	{"id": "hat", "en": "HAT", "pl": "CZAPKA"},
	{"id": "clock", "en": "CLOCK", "pl": "ZEGAR"},
]

## How many pictures a child chooses between, including the correct one.
const CHOICE_COUNT := 3


static func is_supported(language: String) -> bool:
	return language in LANGUAGES


static func concept_ids() -> Array[String]:
	var ids: Array[String] = []
	for concept in CONCEPTS:
		ids.append(concept["id"])
	return ids


static func find(concept_id: String) -> Dictionary:
	for concept in CONCEPTS:
		if concept["id"] == concept_id:
			return concept
	return {}


## The word for a concept in the given language, uppercase.
static func word_for(concept_id: String, language: String) -> String:
	var concept := find(concept_id)
	if concept.is_empty():
		return ""
	return concept.get(language, "")


static func image_path(concept_id: String) -> String:
	return "res://assets/images/%s.svg" % concept_id


## Picks a concept plus CHOICE_COUNT - 1 distractors to show beside it.
##
## [param exclude] lets a session avoid repeating words it has already used.
## Returns { "concept_id": String, "choices": Array[String] } where choices is
## already shuffled, or an empty dictionary when the bank is too small.
static func draw_round(rng: RandomNumberGenerator, exclude: Array = []) -> Dictionary:
	var available := concept_ids()
	var pool := available.filter(func(id): return not exclude.has(id))
	# Fall back to the full bank rather than failing once everything is used.
	if pool.is_empty():
		pool = available
	if available.size() < CHOICE_COUNT:
		return {}

	var answer: String = pool[rng.randi_range(0, pool.size() - 1)]

	var distractor_pool := available.filter(func(id): return id != answer)
	_shuffle(distractor_pool, rng)

	var choices: Array[String] = [answer]
	for i in CHOICE_COUNT - 1:
		choices.append(distractor_pool[i])
	_shuffle(choices, rng)

	return {"concept_id": answer, "choices": choices}


## Fisher-Yates using our own RNG, so a seed reproduces an entire game.
static func _shuffle(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp
