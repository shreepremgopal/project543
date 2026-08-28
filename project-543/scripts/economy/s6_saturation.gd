class_name S6SaturationState
extends RefCounted

var values: Dictionary = {}

func _key(
	party_id: String,
	constituency_id: String,
	action_family: String
) -> String:
	return "%s|%s|%s" % [
		party_id,
		constituency_id,
		action_family
	]

func get_value(
	party_id: String,
	constituency_id: String,
	action_family: String
) -> float:
	var key := _key(
		party_id,
		constituency_id,
		action_family
	)

	return float(values.get(key, 0.0))

func calculate_multiplier(
	party_id: String,
	constituency_id: String,
	action_family: String,
	config: S6EconomyConfig
) -> float:
	var saturation := get_value(
		party_id,
		constituency_id,
		action_family
	)

	var multiplier := 1.0 / (1.0 + saturation)

	return max(
		config.saturation_floor,
		multiplier
	)

func apply(
	party_id: String,
	constituency_id: String,
	action_family: String,
	response: float
) -> bool:
	if party_id.strip_edges().is_empty():
		return false

	if constituency_id.strip_edges().is_empty():
		return false

	if action_family.strip_edges().is_empty():
		return false

	if not is_finite(response) or response <= 0.0:
		return false

	var key := _key(
		party_id,
		constituency_id,
		action_family
	)

	var current := float(values.get(key, 0.0))

	values[key] = clamp(
		current + response,
		0.0,
		1_000_000.0
	)

	return true

func decay_all(config: S6EconomyConfig) -> void:
	var keys := values.keys()

	for key in keys:
		var current := float(values[key])

		current = max(
			0.0,
			current - config.saturation_decay
		)

		values[key] = current

func validate() -> Array[String]:
	var errors: Array[String] = []

	for key in values:
		var value := float(values[key])

		if not is_finite(value) or value < 0.0:
			errors.append(
				"invalid saturation '%s'=%s"
				% [key, value]
			)

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	var result := {}

	var keys := values.keys()
	keys.sort()

	for key in keys:
		result[String(key)] = float(values[key])

	return result

static func from_dictionary(data: Dictionary) -> S6SaturationState:
	var result := S6SaturationState.new()

	for key in data:
		result.values[String(key)] = float(data[key])

	return result
