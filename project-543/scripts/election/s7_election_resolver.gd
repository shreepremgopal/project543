class_name S7ElectionResolver
extends RefCounted

const RESULT_OK := "OK"
const INVALID_INPUT := "INVALID_INPUT"
const NO_PARTIES := "NO_PARTIES"
const NO_CONSTITUENCIES := "NO_CONSTITUENCIES"

## Deterministic 543-seat election resolution.
##
## Expected constituency shape:
## {
##   "constituency_id": String,
##   "personas": Array,
##   "base_support": Dictionary,
##   "turnout": float,
##   "home_party_id": String
## }
##
## Expected persona shape:
## {
##   "weight": float,
##   "ideology": Dictionary
## }
##
## Party shape:
## {
##   "party_id": String,
##   "ideology": Dictionary
## }
##
## Optional constituency support may be supplied as base_support[party_id].
## Campaign modifiers are read from campaign_state["constituencies"] and may
## contain per-party support_delta values. All arithmetic is deterministic.

func resolve(
	parties: Array,
	constituencies: Array,
	campaign_state: Dictionary = {}
) -> Dictionary:
	if parties.is_empty():
		return _failure(NO_PARTIES, ["at least one party is required"])
	if constituencies.is_empty():
		return _failure(NO_CONSTITUENCIES, ["at least one constituency is required"])

	var party_ids: Array[String] = []
	var party_by_id: Dictionary = {}
	for party in parties:
		if not party is Dictionary:
			return _failure(INVALID_INPUT, ["party must be a Dictionary"])
		var party_id := str(party.get("party_id", ""))
		if party_id.is_empty() or party_by_id.has(party_id):
			return _failure(INVALID_INPUT, ["party_id must be unique and non-empty"])
		party_ids.append(party_id)
		party_by_id[party_id] = party

	var results: Array = []
	var seat_totals: Dictionary = {}
	for party_id in party_ids:
		seat_totals[party_id] = 0

	for constituency in constituencies:
		if not constituency is Dictionary:
			return _failure(INVALID_INPUT, ["constituency must be a Dictionary"])
		var result := _resolve_constituency(
			constituency,
			party_ids,
			party_by_id,
			campaign_state
		)
		if not result.ok:
			return result
		results.append(result.constituency)
		var winner_id: String = result.constituency.winner_party_id
		seat_totals[winner_id] = int(seat_totals.get(winner_id, 0)) + 1

	return {
		"ok": true,
		"success": true,
		"code": RESULT_OK,
		"seat_count": results.size(),
		"constituency_results": results,
		"seat_totals": seat_totals,
		"winner_party_id": _national_winner(seat_totals, party_ids)
	}


func _resolve_constituency(
	constituency: Dictionary,
	party_ids: Array[String],
	party_by_id: Dictionary,
	campaign_state: Dictionary
) -> Dictionary:
	var constituency_id := str(constituency.get("constituency_id", ""))
	if constituency_id.is_empty():
		return _failure(INVALID_INPUT, ["constituency_id must not be empty"])

	var personas: Array = constituency.get("personas", [])
	var base_support: Dictionary = constituency.get("base_support", {})
	var modifiers: Dictionary = campaign_state.get("constituencies", {}).get(constituency_id, {})
	var turnout := clampf(float(constituency.get("turnout", 1.0)), 0.0, 1.0)
	var home_party_id := str(constituency.get("home_party_id", ""))

	var votes: Dictionary = {}
	for party_id in party_ids:
		var score := float(base_support.get(party_id, 0.0))
		score += float(modifiers.get("support_delta", {}).get(party_id, 0.0))
		score += _ideological_score(party_by_id[party_id], personas)
		if party_id == home_party_id:
			score += float(constituency.get("home_advantage", 0.0))
		votes[party_id] = maxf(0.0, score * turnout)

	var winner := _winner_from_scores(votes, party_ids)
	return {
		"ok": true,
		"constituency": {
			"constituency_id": constituency_id,
			"winner_party_id": winner,
			"votes": votes,
			"margin": _margin(votes, winner),
			"turnout": turnout,
			"home_party_id": home_party_id
		}
	}


func _ideological_score(party: Dictionary, personas: Array) -> float:
	if personas.is_empty():
		return 0.0
	var party_ideology: Dictionary = party.get("ideology", {})
	var weighted_score := 0.0
	var total_weight := 0.0
	for persona in personas:
		if not persona is Dictionary:
			continue
		var weight := maxf(0.0, float(persona.get("weight", 1.0)))
		var ideology: Dictionary = persona.get("ideology", {})
		if weight <= 0.0:
			continue
		var distance := 0.0
		var dimensions := 0
		for key in ideology.keys():
			if party_ideology.has(key):
			var delta := float(party_ideology[key]) - float(ideology[key])
			distance += delta * delta
			dimensions += 1
		if dimensions > 0:
			weighted_score += weight * (1.0 - sqrt(distance / float(dimensions)))
			total_weight += weight
	if total_weight <= 0.0:
		return 0.0
	return weighted_score / total_weight


func _winner_from_scores(scores: Dictionary, party_ids: Array[String]) -> String:
	var winner := party_ids[0]
	var best := float(scores.get(winner, 0.0))
	for party_id in party_ids:
		var value := float(scores.get(party_id, 0.0))
		# Stable party_ids order is the deterministic tie-break rule.
		if value > best:
			best = value
			winner = party_id
	return winner


func _margin(scores: Dictionary, winner: String) -> float:
	var values: Array[float] = []
	for party_id in scores.keys():
		if party_id != winner:
			values.append(float(scores[party_id]))
	if values.is_empty():
		return float(scores.get(winner, 0.0))
	values.sort()
	return float(scores.get(winner, 0.0)) - values.back()


func _national_winner(totals: Dictionary, party_ids: Array[String]) -> String:
	return _winner_from_scores(totals, party_ids)


func _failure(code: String, errors: Array = []) -> Dictionary:
	return {
		"ok": false,
		"success": false,
		"code": code,
		"errors": errors
	}
