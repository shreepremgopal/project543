class_name PoliticalState
extends RefCounted


var model_version: String = (
	PoliticalBalanceConfig.MODEL_VERSION
)

var config_version: String = (
	PoliticalBalanceConfig.CONFIG_VERSION
)

var turn: int = 1

var support_by_constituency: Dictionary = {}
var explanations_by_constituency: Dictionary = {}

var information_state := PoliticalInformationState.new()


func set_result(
	constituency_id: String,
	result: Dictionary
) -> void:
	support_by_constituency[
		constituency_id
	] = result.get(
		"support",
		{}
	).duplicate(true)

	explanations_by_constituency[
		constituency_id
	] = result.get(
		"explanations",
		{}
	).duplicate(true)


func get_support(
	constituency_id: String
) -> Dictionary:
	if not support_by_constituency.has(
		constituency_id
	):
		return {}

	return support_by_constituency[
		constituency_id
	].duplicate(true)


func get_leading_party_id(
	constituency_id: String
) -> String:
	var support := get_support(
		constituency_id
	)

	var leader := ""
	var best := -1.0

	for party_id in support.keys():
		var value := float(
			support[party_id]
		)

		if value > best:
			best = value
			leader = String(party_id)

	return leader


func get_explanation(
	constituency_id: String,
	party_id: String
) -> PoliticalExplanation:
	if not explanations_by_constituency.has(
		constituency_id
	):
		return null

	var explanations: Dictionary = (
		explanations_by_constituency[
			constituency_id
		]
	)

	if not explanations.has(party_id):
		return null

	return explanations[party_id]


func advance_turn(
	new_turn: int
) -> bool:
	if new_turn < turn:
		return false

	turn = new_turn

	return information_state.advance_turn(
		new_turn
	)


func to_dictionary() -> Dictionary:
	var support := {}
	var explanations := {}

	var ids: Array[String] = []

	for key in support_by_constituency.keys():
		ids.append(String(key))

	ids.sort()

	for constituency_id in ids:
		support[constituency_id] = (
			support_by_constituency[
				constituency_id
			]
		)

		var serialized_explanations := {}

		var party_ids: Array[String] = []

		var raw: Dictionary = (
			explanations_by_constituency.get(
				constituency_id,
				{}
			)
		)

		for party_id in raw.keys():
			party_ids.append(String(party_id))

		party_ids.sort()

		for party_id in party_ids:
			var explanation = raw[party_id]

			if explanation is PoliticalExplanation:
				serialized_explanations[
					party_id
				] = explanation.to_dictionary()
			else:
				serialized_explanations[
					party_id
				] = explanation

		explanations[
			constituency_id
		] = serialized_explanations

	return {
		"model_version": model_version,
		"config_version": config_version,
		"turn": turn,
		"support": support,
		"explanations": explanations,
		"information": information_state.to_dictionary()
	}


static func from_dictionary(
	data: Dictionary
) -> PoliticalState:
	var state := PoliticalState.new()

	state.model_version = String(
		data.get(
			"model_version",
			PoliticalBalanceConfig.MODEL_VERSION
		)
	)

	state.config_version = String(
		data.get(
			"config_version",
			PoliticalBalanceConfig.CONFIG_VERSION
		)
	)

	state.turn = int(
		data.get("turn", 1)
	)

	state.support_by_constituency = (
		data.get(
			"support",
			{}
		).duplicate(true)
	)

	state.information_state = (
		PoliticalInformationState.from_dictionary(
			data.get(
				"information",
				{}
			)
		)
	)

	return state
