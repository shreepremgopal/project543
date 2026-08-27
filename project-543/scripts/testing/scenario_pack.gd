class_name ScenarioPack
extends RefCounted

var scenario_id: String
var description: String
var state: SimulationState

func _init(id_value: String = "", description_value: String = "") -> void:
	scenario_id = id_value
	description = description_value
	state = SimulationState.new()

func validate() -> Array[String]:
	var errors: Array[String] = []
	if scenario_id.strip_edges().is_empty():
		errors.append("ScenarioPack.scenario_id must not be empty")
	if description.strip_edges().is_empty():
		errors.append("ScenarioPack.description must not be empty")
	errors.append_array(state.validate())
	return errors

func to_dictionary() -> Dictionary:
	return {
		"scenario_id": scenario_id,
		"description": description,
		"state": state.to_dictionary()
	}

static func from_dictionary(data: Dictionary) -> ScenarioPack:
	var pack := ScenarioPack.new(
		String(data.get("scenario_id", "")),
		String(data.get("description", ""))
	)
	pack.state = SimulationState.from_dictionary(data.get("state", {}))
	return pack
