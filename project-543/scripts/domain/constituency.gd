class_name Constituency
extends RefCounted

var unique_id: String
var name: String
var state_ut: String
var state_ut_code: String
var gis_reference: String
var population: int
var has_turnout: bool
var turnout: float
var persona_distribution: PersonaDistribution
var provenance: Dictionary

func _init(
	id_value: String = "",
	name_value: String = "",
	state_value: String = "",
	state_code_value: String = "",
	gis_reference_value: String = "",
	population_value: int = 0,
	turnout_value: float = 0.0,
	has_turnout_value: bool = false,
	distribution_value: PersonaDistribution = null,
	provenance_value: Dictionary = {}
) -> void:
	unique_id = id_value
	name = name_value
	state_ut = state_value
	state_ut_code = state_code_value
	gis_reference = gis_reference_value
	population = population_value
	has_turnout = has_turnout_value
	turnout = turnout_value
	persona_distribution = distribution_value if distribution_value != null else PersonaDistribution.new()
	provenance = provenance_value.duplicate(true)

func validate(persona_registry: PersonaRegistry = null, require_complete: bool = false) -> Array[String]:
	var errors: Array[String] = []
	if unique_id.strip_edges().is_empty():
		errors.append("Constituency.unique_id must not be empty")
	if name.strip_edges().is_empty():
		errors.append("Constituency.name must not be empty")
	if population < 0:
		errors.append("Constituency.population=%s; expected >= 0" % population)
	if has_turnout:
		if not is_finite(turnout) or turnout < 0.0 or turnout > 1.0:
			errors.append("Constituency.turnout=%s; expected [0, 1]" % turnout)
	if persona_distribution == null:
		errors.append("Constituency.persona_distribution must not be null")
	elif require_complete:
		errors.append_array(persona_distribution.validate(persona_registry, true))
	elif not persona_distribution.shares.is_empty():
		errors.append_array(persona_distribution.validate(persona_registry, true))
	if require_complete and population <= 0:
		errors.append("Constituency.population must be > 0 for a complete political fixture")
	if require_complete and not has_turnout:
		errors.append("Constituency.turnout must be supplied for a complete political fixture")
	return errors

func is_valid(persona_registry: PersonaRegistry = null, require_complete: bool = false) -> bool:
	return validate(persona_registry, require_complete).is_empty()

func to_dictionary() -> Dictionary:
	return {
		"unique_id": unique_id,
		"name": name,
		"state_ut": state_ut,
		"state_ut_code": state_ut_code,
		"gis_reference": gis_reference,
		"population": population,
		"has_turnout": has_turnout,
		"turnout": turnout,
		"persona_distribution": persona_distribution.to_dictionary(),
		"provenance": provenance.duplicate(true)
	}

static func from_dictionary(data: Dictionary) -> Constituency:
	return Constituency.new(
		String(data.get("unique_id", "")),
		String(data.get("name", "")),
		String(data.get("state_ut", "")),
		String(data.get("state_ut_code", "")),
		String(data.get("gis_reference", "")),
		int(data.get("population", 0)),
		float(data.get("turnout", 0.0)),
		bool(data.get("has_turnout", false)),
		PersonaDistribution.from_dictionary(data.get("persona_distribution", {})),
		data.get("provenance", {})
	)
