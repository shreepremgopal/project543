class_name PersonaDistribution
extends RefCounted

const TOTAL_UNITS: int = 10000

var shares: Dictionary = {}

func _init(initial_shares: Dictionary = {}) -> void:
	for persona_id in initial_shares:
		set_share(String(persona_id), int(initial_shares[persona_id]))

func set_share(persona_id: String, units: int) -> void:
	shares[persona_id] = units

func get_share_units(persona_id: String) -> int:
	return int(shares.get(persona_id, 0))

func get_share(persona_id: String) -> float:
	return float(get_share_units(persona_id)) / float(TOTAL_UNITS)

func total_units() -> int:
	var total: int = 0
	for persona_id in shares:
		total += get_share_units(String(persona_id))
	return total

func validate(persona_registry: PersonaRegistry = null, require_total: bool = true) -> Array[String]:
	var errors: Array[String] = []
	for persona_id in shares:
		var id := String(persona_id)
		var units := get_share_units(id)
		if units < 0 or units > TOTAL_UNITS:
			errors.append(
				"PersonaDistribution.%s=%s; expected integer units in [0, %s]"
				% [id, units, TOTAL_UNITS]
			)
		if persona_registry != null and not persona_registry.has(id):
			errors.append("PersonaDistribution references unknown persona '%s'" % id)

	if require_total and total_units() != TOTAL_UNITS:
		errors.append(
			"PersonaDistribution total=%s units; expected %s"
			% [total_units(), TOTAL_UNITS]
		)
	return errors

func is_valid(persona_registry: PersonaRegistry = null) -> bool:
	return validate(persona_registry).is_empty()

func to_dictionary() -> Dictionary:
	var ids: Array[String] = []
	for persona_id in shares:
		ids.append(String(persona_id))
	ids.sort()

	var result: Dictionary = {}
	for persona_id in ids:
		result[persona_id] = get_share_units(persona_id)
	return result

static func from_dictionary(data: Dictionary) -> PersonaDistribution:
	return PersonaDistribution.new(data)
