class_name S6CampaignEffect
extends RefCounted

var effect_id: String
var source_action_id: String

var party_id: String
var constituency_id: String
var action_type: String

var magnitude: float

var start_turn: int
var duration: int
var permanent: bool

var causal_metadata: Dictionary = {}

func _init(
	effect_id_value: String = "",
	source_action_id_value: String = "",
	party_id_value: String = "",
	constituency_id_value: String = "",
	action_type_value: String = "",
	magnitude_value: float = 0.0,
	start_turn_value: int = 1,
	duration_value: int = 0,
	permanent_value: bool = false,
	causal_metadata_value: Dictionary = {}
) -> void:
	effect_id = effect_id_value
	source_action_id = source_action_id_value
	party_id = party_id_value
	constituency_id = constituency_id_value
	action_type = action_type_value
	magnitude = magnitude_value
	start_turn = start_turn_value
	duration = duration_value
	permanent = permanent_value
	causal_metadata = causal_metadata_value.duplicate(true)

func validate() -> Array[String]:
	var errors: Array[String] = []

	if effect_id.strip_edges().is_empty():
		errors.append("effect_id must not be empty")

	if source_action_id.strip_edges().is_empty():
		errors.append("source_action_id must not be empty")

	if party_id.strip_edges().is_empty():
		errors.append("party_id must not be empty")

	if constituency_id.strip_edges().is_empty():
		errors.append("constituency_id must not be empty")

	if action_type.strip_edges().is_empty():
		errors.append("action_type must not be empty")

	if not is_finite(magnitude):
		errors.append("magnitude must be finite")

	if start_turn < 1:
		errors.append("start_turn must be >= 1")

	if duration < 0:
		errors.append("duration must be >= 0")

	if permanent and duration != 0:
		errors.append("permanent effect must have duration 0")

	if not permanent and duration <= 0:
		errors.append("temporary effect must have duration > 0")

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func is_active(current_turn: int) -> bool:
	if current_turn < start_turn:
		return false

	if permanent:
		return true

	return current_turn < start_turn + duration

func remaining_duration(current_turn: int) -> int:
	if permanent:
		return -1

	if current_turn < start_turn:
		return duration

	return max(0, (start_turn + duration) - current_turn)

func to_dictionary() -> Dictionary:
	return {
		"effect_id": effect_id,
		"source_action_id": source_action_id,
		"party_id": party_id,
		"constituency_id": constituency_id,
		"action_type": action_type,
		"magnitude": magnitude,
		"start_turn": start_turn,
		"duration": duration,
		"permanent": permanent,
		"causal_metadata": causal_metadata.duplicate(true)
	}

static func from_dictionary(data: Dictionary) -> S6CampaignEffect:
	return S6CampaignEffect.new(
		String(data.get("effect_id", "")),
		String(data.get("source_action_id", "")),
		String(data.get("party_id", "")),
		String(data.get("constituency_id", "")),
		String(data.get("action_type", "")),
		float(data.get("magnitude", 0.0)),
		int(data.get("start_turn", 1)),
		int(data.get("duration", 0)),
		bool(data.get("permanent", false)),
		data.get("causal_metadata", {})
	)
