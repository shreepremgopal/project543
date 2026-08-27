class_name PoliticalStateChange
extends RefCounted

var source_system: String
var source_action: String
var turn: int
var target_id: String
var state_type: String
var delta: float
var reason_code: String

func _init(
	source_system_value: String = "",
	source_action_value: String = "",
	turn_value: int = 0,
	target_id_value: String = "",
	state_type_value: String = "",
	delta_value: float = 0.0,
	reason_code_value: String = ""
) -> void:
	source_system = source_system_value
	source_action = source_action_value
	turn = turn_value
	target_id = target_id_value
	state_type = state_type_value
	delta = delta_value
	reason_code = reason_code_value

func validate() -> Array[String]:
	var errors: Array[String] = []
	if source_system.strip_edges().is_empty():
		errors.append("PoliticalStateChange.source_system must not be empty")
	if source_action.strip_edges().is_empty():
		errors.append("PoliticalStateChange.source_action must not be empty")
	if turn < 0:
		errors.append("PoliticalStateChange.turn=%s; expected >= 0" % turn)
	if target_id.strip_edges().is_empty():
		errors.append("PoliticalStateChange.target_id must not be empty")
	if state_type.strip_edges().is_empty():
		errors.append("PoliticalStateChange.state_type must not be empty")
	if not is_finite(delta):
		errors.append("PoliticalStateChange.delta must be finite")
	if reason_code.strip_edges().is_empty():
		errors.append("PoliticalStateChange.reason_code must not be empty")
	return errors

func to_dictionary() -> Dictionary:
	return {
		"source_system": source_system,
		"source_action": source_action,
		"turn": turn,
		"target_id": target_id,
		"state_type": state_type,
		"delta": delta,
		"reason_code": reason_code
	}

static func from_dictionary(data: Dictionary) -> PoliticalStateChange:
	return PoliticalStateChange.new(
		String(data.get("source_system", "")),
		String(data.get("source_action", "")),
		int(data.get("turn", 0)),
		String(data.get("target_id", "")),
		String(data.get("state_type", "")),
		float(data.get("delta", 0.0)),
		String(data.get("reason_code", ""))
	)
