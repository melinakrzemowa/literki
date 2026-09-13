## A full game: ten rounds in one language, with a running total.
##
## The total is derived rather than accumulated — banked points from finished
## rounds plus whatever the current round has earned so far — so the number in
## the corner can never drift out of step with the rounds behind it.
class_name GameSession
extends RefCounted

const ROUNDS_PER_GAME := 10

var language: String
var round_number := 0  ## 1-based once the first round starts, 0 before that.
var round_state: RoundState = null

var _banked := 0
var _used: Array[String] = []
var _rng := RandomNumberGenerator.new()


func _init(p_language: String, p_seed: int = 0) -> void:
	language = p_language
	if p_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = p_seed


## Points so far, including the round in progress.
func total_score() -> int:
	var live := round_state.score if round_state != null else 0
	return Scoring.clamp_total(_banked + live)


func is_finished() -> bool:
	return round_number >= ROUNDS_PER_GAME and (round_state == null or round_state.phase == RoundState.Phase.DONE)


## Banks the finished round and deals the next one, or returns null after the
## tenth round.
func start_next_round() -> RoundState:
	if round_state != null:
		_banked += round_state.score
		round_state = null
	if round_number >= ROUNDS_PER_GAME:
		return null

	var deal := WordBank.draw_round(_rng, _used)
	if deal.is_empty():
		return null

	var concept_id: String = deal["concept_id"]
	var choices: Array[String] = deal["choices"]
	var word := WordBank.word_for(concept_id, language)
	if word.is_empty():
		return null

	_used.append(concept_id)
	round_number += 1
	round_state = RoundState.new(concept_id, word, choices)
	return round_state
