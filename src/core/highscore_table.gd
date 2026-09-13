## Sorting and trimming rules for the highscore list.
##
## Pure functions over plain arrays so they can be tested without touching the
## filesystem; the Scores autoload handles the reading and writing.
class_name HighscoreTable
extends RefCounted

const MAX_ENTRIES := 10
const MAX_NAME_LENGTH := 12
const DEFAULT_NAME := "?"


## Highest score first; on a tie the score set earlier keeps the better slot.
static func sorted(entries: Array) -> Array:
	var copy := entries.duplicate(true)
	copy.sort_custom(func(a, b):
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		return str(a.get("date", "")) < str(b.get("date", ""))
	)
	return copy


## Adds an entry and trims the list back to MAX_ENTRIES.
static func insert(entries: Array, entry: Dictionary) -> Array:
	var combined := entries.duplicate(true)
	combined.append(entry)
	var ordered := sorted(combined)
	return ordered.slice(0, MAX_ENTRIES)


## True when a score would earn a place on a full board.
static func qualifies(entries: Array, score: int) -> bool:
	if entries.size() < MAX_ENTRIES:
		return true
	var ordered := sorted(entries)
	return score > int(ordered[-1].get("score", 0))


## Trims a typed-in name to something safe to draw and store.
static func sanitize_name(raw: String) -> String:
	var name := raw.strip_edges()
	if name.length() > MAX_NAME_LENGTH:
		name = name.substr(0, MAX_NAME_LENGTH)
	if name.is_empty():
		return DEFAULT_NAME
	return name


## Drops anything that is not a well-formed entry, so a hand-edited or
## truncated save file degrades to "fewer scores" instead of breaking the board.
static func validate(raw: Variant) -> Array:
	var clean: Array = []
	if not (raw is Array):
		return clean
	for item in raw:
		if not (item is Dictionary):
			continue
		if not item.has("name") or not item.has("score"):
			continue
		clean.append({
			"name": sanitize_name(str(item["name"])),
			"score": int(item["score"]),
			"language": str(item.get("language", "")),
			"date": str(item.get("date", "")),
		})
	return sorted(clean).slice(0, MAX_ENTRIES)
