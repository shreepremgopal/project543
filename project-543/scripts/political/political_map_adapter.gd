class_name PoliticalMapAdapter
extends RefCounted


static func leading_party_id(
	political_state: PoliticalState,
	constituency_id: String
) -> String:
	if political_state == null:
		return ""

	return political_state.get_leading_party_id(
		constituency_id
	)


static func leading_party_colour(
	political_state: PoliticalState,
	party_registry: PartyRegistry,
	constituency_id: String
) -> Color:
	if political_state == null:
		return Color.WHITE

	if party_registry == null:
		return Color.WHITE

	var party_id := leading_party_id(
		political_state,
		constituency_id
	)

	if party_id.is_empty():
		return Color.WHITE

	var party := (
		party_registry.get_definition(
			party_id
		)
	)

	if party == null:
		return Color.WHITE

	return Color.from_string(
		party.colour,
		Color.WHITE
	)