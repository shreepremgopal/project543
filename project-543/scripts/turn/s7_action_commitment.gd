class_name S7ActionCommitment
extends RefCounted

var action_id: String = ""
var party_id: String = ""
var target: String = ""
var parameters: Dictionary = {}
var turn: int = 1
var sequence: int = 1
var cost: int = 0

var committed: bool = false


func _init(
	action_id_value: String = "",
	party_id_value: String = "",
	target_value: String = "",
	parameters_value: Dictionary = {},
	turn_value: int = 1,
	sequence_value: int = 1,
	cost_value: int = 0
) -> void:
	action_id = action_id_value
	party_id = party_id_value
	target = target_value
	parameters = parameters_value.duplicate(true)
	turn = turn_value
	sequence = sequence_value
	cost = cost_value


func validate() -> Array:
	var errors: Array = []

	if action_id.strip_edges().is_empty():
		errors.append("action_id must not be empty")

	if party_id.strip_edges().is_empty():
		errors.append("party_id must not be empty")

	if target.strip_edges().is_empty():
		errors.append("target must not be empty")

	if turn < 1:
		errors.append("turn must be >= 1")

	if sequence < 1:
		errors.append("sequence must be >= 1")

	if cost < 0:
		errors.append("cost must be >= 0")

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func commit() -> void:
	committed = true


func snapshot():
	var result = S7ActionCommitment.new(
		action_id,
		party_id,
		target,
		parameters,
		turn,
		sequence,
		cost
	)

	result.committed = committed

	return result


func to_dictionary() -> Dictionary:
	return {
		"action_id": action_id,
		"party_id": party_id,
		"target": target,
		"parameters": parameters.duplicate(true),
		"turn": turn,
		"sequence": sequence,
		"cost": cost,
		"committed": committed
	}


static func from_dictionary(data: Dictionary):
	var result = S7ActionCommitment.new(
		str(data.get("action_id", "")),
		str(data.get("party_id", "")),
		str(data.get("target", "")),
		data.get("parameters", {}),
		int(data.get("turn", 1)),
		int(data.get("sequence", 1)),
		int(data.get("cost", 0))
	)

	result.committed = bool(data.get("committed", false))

	return result
