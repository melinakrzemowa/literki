## One round: type a word letter by letter, hear it spelled back, then pick the
## picture it describes. Pure logic — it holds no nodes and draws nothing, so
## the whole round can be played out in a headless test.
class_name RoundState
extends RefCounted

enum Phase {
	TYPING,    ## A letter is on screen waiting to be typed.
	SPELLING,  ## The finished word is being read back, letter by letter.
	PICKING,   ## Three pictures are on screen, one of them correct.
	DONE,      ## The right picture was chosen.
}

var concept_id: String
var word: String
var choices: Array[String] = []
var phase: Phase = Phase.TYPING

## How many letters of [member word] have been typed correctly so far.
var typed_count := 0
## Indices of pictures already tried and rejected.
var rejected: Array[int] = []
## Points earned in this round, letters and picture together.
var score := 0


func _init(p_concept_id: String, p_word: String, p_choices: Array[String]) -> void:
	concept_id = p_concept_id
	word = p_word
	choices = p_choices


## The letter the child is being asked for, or "" once the word is finished.
func current_letter() -> String:
	if typed_count >= word.length():
		return ""
	return word[typed_count]


## The part of the word already spelled out along the top row.
func typed_word() -> String:
	return word.substr(0, typed_count)


func is_word_complete() -> bool:
	return typed_count >= word.length()


## Index into [member choices] of the picture that matches the word.
func correct_index() -> int:
	return choices.find(concept_id)


## Handles one keystroke.
##
## Returns { "accepted": bool, "delta": int, "letter": String,
##           "word_complete": bool }. [code]accepted[/code] is false and delta
## zero when the keystroke arrived outside the typing phase, so a stray key
## during an animation never costs a point.
func type_letter(character: String) -> Dictionary:
	var ignored := {"accepted": false, "delta": 0, "letter": "", "word_complete": false}
	if phase != Phase.TYPING or is_word_complete():
		return ignored
	if not Letters.is_typable(character):
		return ignored

	var expected := current_letter()
	if not Letters.matches(character, expected):
		score += Scoring.LETTER_WRONG
		return {
			"accepted": true,
			"delta": Scoring.LETTER_WRONG,
			"letter": expected,
			"word_complete": false,
		}

	typed_count += 1
	score += Scoring.LETTER_CORRECT
	var complete := is_word_complete()
	if complete:
		phase = Phase.SPELLING
	return {
		"accepted": true,
		"delta": Scoring.LETTER_CORRECT,
		"letter": expected,
		"word_complete": complete,
	}


## Called once the read-back finishes and the pictures go up.
func begin_picking() -> void:
	if phase == Phase.SPELLING:
		phase = Phase.PICKING


## Handles a picture being clicked.
##
## Returns { "accepted": bool, "correct": bool, "delta": int, "attempt": int }.
## A wrong picture is greyed out and the round stays in the picking phase, so
## the child keeps choosing until they find the right one.
func pick(index: int) -> Dictionary:
	var ignored := {"accepted": false, "correct": false, "delta": 0, "attempt": 0}
	if phase != Phase.PICKING:
		return ignored
	if index < 0 or index >= choices.size():
		return ignored
	if rejected.has(index):
		return ignored

	var attempt := rejected.size()
	if choices[index] != concept_id:
		rejected.append(index)
		return {"accepted": true, "correct": false, "delta": 0, "attempt": attempt}

	var points := Scoring.picture_points(attempt)
	score += points
	phase = Phase.DONE
	return {"accepted": true, "correct": true, "delta": points, "attempt": attempt}
