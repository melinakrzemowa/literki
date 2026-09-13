## Every scoring rule in the game, in one place.
class_name Scoring
extends RefCounted

## Typing the letter the game is asking for.
const LETTER_CORRECT := 1

## Any other letter key while a letter is on screen.
const LETTER_WRONG := -1

## Points for picking the right picture, indexed by how many tries it took.
## With three pictures a child can be wrong at most twice, so three entries
## cover every case.
const PICTURE_BY_ATTEMPT := [3, 2, 1]

## When false the running total stops at zero instead of going negative.
## Kept true to match the rules as specified; flip it for a gentler game.
const ALLOW_NEGATIVE_TOTAL := true


static func picture_points(attempt_index: int) -> int:
	if attempt_index < 0 or attempt_index >= PICTURE_BY_ATTEMPT.size():
		return PICTURE_BY_ATTEMPT[-1]
	return PICTURE_BY_ATTEMPT[attempt_index]


static func clamp_total(total: int) -> int:
	if ALLOW_NEGATIVE_TOTAL:
		return total
	return maxi(total, 0)
