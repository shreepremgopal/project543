class_name PersonaDefinition
extends RefCounted

var persona_id: String
var display_name: String
var ideology_profile: IdeologyProfile
var priority_weights: Dictionary
var has_turnout_tendency: bool
var turnout_tendency: float
var approved: bool
var provenance: Dictionary

func _init(
	id_value: String = "",
	name_value: String = "",
	profile_value: IdeologyProfile = null,
	weights_value: Dictionary = {},
	approved_value: bool = false,
	has_turnout_value: bool = false,
	turnout_value: float = 0.0,
	provenance_value: Dictionary = {}
) -> void:
	persona_id = id_value
	display_name = name_value
	ideology_profile = profile_value if profile_value != null else IdeologyProfile.new()
	priority_weights = weights_value.duplicate(true)
	approved = approved_value
	has_turnout_tendency = has_turnout_value
	turnout_tendency = turnout_value
	provenance = provenance_value.duplicate(true)

func validate() -> Array[String]:
	var errors: Array[String] = []
	if persona_id.strip_edges().is_empty():
		errors.append("PersonaDefinition.persona_id must not be empty")
	if display_name.strip_edges().is_empty():
		errors.append("PersonaDefinition.display_name must not be empty")
	if ideology_profile == null:
		errors.append("PersonaDefinition.ideology_profile must not be null")
	else:
		errors.append_array(ideology_profile.validate())

	for dimension in priority_weights:
		if not IdeologyProfile.DIMENSIONS.has(String(dimension)):
			errors.append("PersonaDefinition.priority_weights contains unknown dimension '%s'" % dimension)
			continue
		var weight: float = float(priority_weights[dimension])
		if not is_finite(weight) or weight < 0.0:
			errors.append(
				"PersonaDefinition.priority_weights.%s=%s; expected finite value >= 0"
				% [dimension, weight]
			)

	if has_turnout_tendency:
		if not is_finite(turnout_tendency) or turnout_tendency < 0.0 or turnout_tendency > 1.0:
			errors.append(
				"PersonaDefinition.turnout_tendency=%s; expected [0, 1]"
				% turnout_tendency
			)

	return errors

func is_structurally_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	return {
		"persona_id": persona_id,
		"display_name": display_name,
		"ideology_profile": ideology_profile.to_dictionary(),
		"priority_weights": priority_weights.duplicate(true),
		"has_turnout_tendency": has_turnout_tendency,
		"turnout_tendency": turnout_tendency,
		"approved": approved,
		"provenance": provenance.duplicate(true)
	}

static func from_dictionary(data: Dictionary) -> PersonaDefinition:
	var profile_data: Dictionary = data.get("ideology_profile", {})
	return PersonaDefinition.new(
		String(data.get("persona_id", "")),
		String(data.get("display_name", "")),
		IdeologyProfile.from_dictionary(profile_data),
		data.get("priority_weights", {}),
		bool(data.get("approved", false)),
		bool(data.get("has_turnout_tendency", false)),
		float(data.get("turnout_tendency", 0.0)),
		data.get("provenance", {})
	)
