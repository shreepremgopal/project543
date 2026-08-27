class_name ConstituencyPoliticalProfile
extends RefCounted

const TOTAL_UNITS := PersonaDistribution.TOTAL_UNITS

var constituency_id: String
var distribution: PersonaDistribution
var provenance: Dictionary = {}


func _init(
	id_value: String = "",
	distribution_value: PersonaDistribution = null,
	provenance_value: Dictionary = {}
) -> void:
	constituency_id = id_value
	distribution = (
		distribution_value
		if distribution_value != null
		else PersonaDistribution.new()
	)
	provenance = provenance_value.duplicate(true)


func validate(
	persona_registry: PersonaRegistry
) -> Array[String]:
	var errors: Array[String] = []

	if constituency_id.strip_edges().is_empty():
		errors.append(
			"Political profile constituency_id must not be empty"
		)

	if distribution == null:
		errors.append(
			"Political profile distribution must not be null"
		)
		return errors

	errors.append_array(
		distribution.validate(
			persona_registry,
			true
		)
	)

	return errors


func is_valid(
	persona_registry: PersonaRegistry
) -> bool:
	return validate(persona_registry).is_empty()


func get_share(persona_id: String) -> float:
	if distribution == null:
		return 0.0

	return distribution.get_share(persona_id)


func persona_ids() -> Array[String]:
	if distribution == null:
		return []

	var ids: Array[String] = []

	for key in distribution.shares.keys():
		ids.append(String(key))

	ids.sort()

	return ids


func calculate_affinity(
	party: PartyDefinition,
	persona_registry: PersonaRegistry,
	config: PoliticalBalanceConfig
) -> float:
	if party == null or persona_registry == null:
		return 0.0

	var result := 0.0

	for persona_id in persona_ids():
		var persona := (
			persona_registry.get_definition(persona_id)
		)

		if persona == null:
			continue

		var share := get_share(persona_id)

		var alignment := (
			PersonaAlignmentModel.calculate(
				party.ideological_profile,
				persona,
				config
			)
		)

		result += share * alignment

	return clampf(result, 0.0, 1.0)


func to_dictionary() -> Dictionary:
	return {
		"constituency_id": constituency_id,
		"persona_distribution": (
			distribution.to_dictionary()
		),
		"provenance": provenance.duplicate(true)
	}


static func from_constituency(
	constituency: Constituency
) -> ConstituencyPoliticalProfile:
	return ConstituencyPoliticalProfile.new(
		constituency.unique_id,
		constituency.persona_distribution,
		constituency.provenance
	)


static func from_dictionary(
	data: Dictionary
) -> ConstituencyPoliticalProfile:
	return ConstituencyPoliticalProfile.new(
		String(data.get("constituency_id", "")),
		PersonaDistribution.from_dictionary(
			data.get(
				"persona_distribution",
				{}
			)
		),
		data.get("provenance", {})
	)
