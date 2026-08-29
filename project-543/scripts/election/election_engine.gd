class_name ElectionEngine
extends RefCounted

## Deterministic, UI-independent election calculation.
## Structural support comes from the political model. Campaign state only
## contributes explicit, inspectable modifiers on top of that foundation.

const EPSILON := 0.0000001
const MODEL_VERSION := "election-v0.1"


static func resolve(
	constituency_registry: ConstituencyRegistry,
	party_registry: PartyRegistry,
	persona_registry: PersonaRegistry,
	political_config: PoliticalBalanceConfig,
	campaign_state: Dictionary = {},
	turn: int = 1,
	eligibility_factor: float = 0.65
) -> S7ElectionResult:
	var result := S7ElectionResult.new()
	result.model_version = MODEL_VERSION

	if constituency_registry == null or party_registry == null or persona_registry == null:
		return result
	if political_config == null or not political_config.is_valid():
		return result
	if turn < 1 or not is_finite(eligibility_factor) or eligibility_factor < 0.0 or eligibility_factor > 1.0:
		return result

	var party_ids := party_registry.ids()
	var seat_totals: Dictionary = {}
	var vote_totals: Dictionary = {}
	for party_id in party_ids:
		seat_totals[party_id] = 0
		vote_totals[party_id] = 0

	for constituency_id in constituency_registry.ids():
		var constituency := constituency_registry.get_constituency(constituency_id)
		var seat_result := calculate_constituency(
			constituency,
			party_registry,
			persona_registry,
			political_config,
			campaign_state,
			turn,
			eligibility_factor
		)
		if seat_result.is_empty():
			return S7ElectionResult.new()

		result.constituency_results.append(seat_result)
		var winner := String(seat_result.get("winner_party_id", ""))
		if seat_totals.has(winner):
			seat_totals[winner] = int(seat_totals[winner]) + 1

		var seat_votes: Dictionary = seat_result.get("votes", {})
		for party_id in party_ids:
			vote_totals[party_id] = int(vote_totals[party_id]) + int(seat_votes.get(party_id, 0))

	result.seat_count = result.constituency_results.size()
	result.seat_totals = seat_totals
	result.vote_totals = vote_totals
	result.national_vote_shares = _normalise_totals(vote_totals)
	result.winner_party_id = _winner_from_totals(seat_totals, party_ids)
	result.seed = int(campaign_state.get("seed", 0))
	return result


static func calculate_constituency(
	constituency: Constituency,
	party_registry: PartyRegistry,
	persona_registry: PersonaRegistry,
	political_config: PoliticalBalanceConfig,
	campaign_state: Dictionary = {},
	turn: int = 1,
	eligibility_factor: float = 0.65
) -> Dictionary:
	if constituency == null or party_registry == null or persona_registry == null:
		return {}
	if political_config == null or not political_config.is_valid():
		return {}
	if constituency.population <= 0 or not constituency.has_turnout:
		return {}

	var base_support := _base_support_for_constituency(
		constituency.unique_id,
		party_registry
	)
	var structural := PoliticalSupportModel.calculate(
		constituency.unique_id,
		party_registry,
		persona_registry,
		ConstituencyPoliticalProfile.from_constituency(constituency),
		base_support,
		political_config
	)
	if structural.is_empty():
		return {}

	var party_ids := party_registry.ids()
	var strengths: Dictionary = {}
	var explanations: Dictionary = {}
	var state := campaign_state if campaign_state != null else {}

	for party_id in party_ids:
		var structural_support := float(structural.get("support", {}).get(party_id, 0.0))
		var local_bonus := _local_bonus(state, party_id, constituency.unique_id)
		var temporary_bonus := _temporary_bonus(state, party_id, constituency.unique_id, turn)
		var manifesto_bonus := _manifesto_bonus(
			state,
			party_id,
			constituency,
			turn
		)
		var campaign_bonus := local_bonus + temporary_bonus + manifesto_bonus
		var risk_modifier := _risk_modifier(state, party_id)
		var effective_strength := maxf(EPSILON, structural_support + campaign_bonus) * risk_modifier
		strengths[party_id] = effective_strength
		var structural_explanation = structural.get("explanations", {}).get(party_id, null)
		var constituency_affinity := 0.0
		if structural_explanation is PoliticalExplanation:
			constituency_affinity = structural_explanation.constituency_affinity
		explanations[party_id] = {
			"structural_support": structural_support,
			"base_support": float(base_support.get(party_id, 0.0)),
			"constituency_affinity": constituency_affinity,
			"local_campaign": local_bonus,
			"temporary_campaign": temporary_bonus,
			"manifesto_bonus": manifesto_bonus,
			"campaign_bonus": campaign_bonus,
			"risk_modifier": risk_modifier,
			"effective_strength": effective_strength
		}

	var denominator := 0.0
	for party_id in party_ids:
		denominator += float(strengths[party_id])
	if denominator <= EPSILON:
		return {}

	var shares: Dictionary = {}
	for party_id in party_ids:
		shares[party_id] = float(strengths[party_id]) / denominator

	var total_votes := int(round(float(constituency.population) * eligibility_factor * constituency.turnout))
	total_votes = max(1, total_votes)
	var votes := _allocate_votes(shares, party_ids, total_votes)
	var winner := _winner_from_totals(votes, party_ids)
	var ordered_votes := []
	for party_id in party_ids:
		ordered_votes.append(int(votes.get(party_id, 0)))
	ordered_votes.sort()
	var margin_votes := 0
	if ordered_votes.size() >= 2:
		margin_votes = ordered_votes[ordered_votes.size() - 1] - ordered_votes[ordered_votes.size() - 2]

	for party_id in party_ids:
		var party_explanation: Dictionary = explanations[party_id]
		party_explanation["vote_share"] = float(shares[party_id])
		party_explanation["votes"] = int(votes.get(party_id, 0))
		explanations[party_id] = party_explanation

	return {
		"constituency_id": constituency.unique_id,
		"name": constituency.name,
		"state": constituency.state_ut,
		"population": constituency.population,
		"turnout": constituency.turnout,
		"eligible_votes": total_votes,
		"total_votes": total_votes,
		"structural_support": structural.get("support", {}).duplicate(true),
		"strength": strengths,
		"support": shares.duplicate(true),
		"vote_share": shares.duplicate(true),
		"votes": votes,
		"winner_party_id": winner,
		"margin_votes": margin_votes,
		"margin_share": float(margin_votes) / float(total_votes),
		"explanations": explanations,
		"model_version": MODEL_VERSION,
		"turn": turn
	}


static func _base_support_for_constituency(
	constituency_id: String,
	party_registry: PartyRegistry
) -> Dictionary:
	var result := {}
	for party_id in party_registry.ids():
		var state := party_registry.get_state(party_id)
		result[party_id] = float(state.base_support.get(constituency_id, 0.0)) if state != null else 0.0
	return result


static func _local_bonus(state: Dictionary, party_id: String, constituency_id: String) -> float:
	var local: Dictionary = state.get("local_modifiers", {})
	var party_values: Dictionary = local.get(party_id, {})
	return max(0.0, float(party_values.get(constituency_id, 0.0)))


static func _temporary_bonus(
	state: Dictionary,
	party_id: String,
	constituency_id: String,
	turn: int
) -> float:
	var total := 0.0
	for effect in state.get("temporary_effects", []):
		if String(effect.get("party_id", "")) != party_id:
			continue
		if String(effect.get("constituency_id", "")) != constituency_id:
			continue
		var start_turn := int(effect.get("start_turn", 1))
		var expires_turn := int(effect.get("expires_turn", start_turn))
		if turn >= start_turn and turn < expires_turn:
			total += max(0.0, float(effect.get("magnitude", 0.0)))
	return total


static func _manifesto_bonus(
	state: Dictionary,
	party_id: String,
	constituency: Constituency,
	turn: int
) -> float:
	var manifestos: Dictionary = state.get("active_manifestos", {})
	var manifesto: Dictionary = manifestos.get(party_id, {})
	if manifesto.is_empty():
		return 0.0
	var start_turn := int(manifesto.get("start_turn", 1))
	var expires_turn := int(manifesto.get("expires_turn", start_turn))
	if turn < start_turn or turn >= expires_turn:
		return 0.0

	var focus_share := 0.0
	for persona_id in manifesto.get("focus_personas", []):
		focus_share += constituency.persona_distribution.get_share(String(persona_id))
	var support_effect := max(0.0, float(manifesto.get("support_effect", 0.0)))
	var saturation_multiplier := clampf(float(manifesto.get("saturation_multiplier", 1.0)), 0.0, 1.0)
	return support_effect * saturation_multiplier * (0.25 + focus_share * 2.0)


static func _risk_modifier(state: Dictionary, party_id: String) -> float:
	var remaining: Dictionary = state.get("scandal_remaining", {})
	if int(remaining.get(party_id, 0)) > 0:
		return clampf(float(state.get("risk_scandal_modifier", 0.50)), 0.0, 1.0)
	return 1.0


static func _allocate_votes(shares: Dictionary, party_ids: Array[String], total_votes: int) -> Dictionary:
	var votes := {}
	var remainders := []
	var assigned := 0
	for party_id in party_ids:
		var exact := float(shares.get(party_id, 0.0)) * float(total_votes)
		var whole := int(floor(exact))
		votes[party_id] = whole
		assigned += whole
		remainders.append({"party_id": party_id, "remainder": exact - float(whole)})

	remainders.sort_custom(func(a, b):
		if is_equal_approx(float(a.remainder), float(b.remainder)):
			return String(a.party_id) < String(b.party_id)
		return float(a.remainder) > float(b.remainder)
	)
	var remaining := total_votes - assigned
	for index in range(mini(remaining, remainders.size())):
		var party_id := String(remainders[index].party_id)
		votes[party_id] = int(votes[party_id]) + 1
	return votes


static func _winner_from_totals(totals: Dictionary, party_ids: Array[String]) -> String:
	var winner := ""
	var best := -1
	for party_id in party_ids:
		var value := int(totals.get(party_id, 0))
		if value > best:
			best = value
			winner = party_id
	return winner


static func _normalise_totals(totals: Dictionary) -> Dictionary:
	var total := 0
	for value in totals.values():
		total += int(value)
	var result := {}
	for key in totals.keys():
		result[key] = float(totals[key]) / float(total) if total > 0 else 0.0
	return result
