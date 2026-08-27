class_name PoliticalSupportModel
extends RefCounted


static func calculate(
	constituency_id: String,
	party_registry: PartyRegistry,
	persona_registry: PersonaRegistry,
	political_profile: ConstituencyPoliticalProfile,
	base_support: Dictionary,
	config: PoliticalBalanceConfig
) -> Dictionary:
	var empty_result := {
		"support": {},
		"potential": {},
		"explanations": {},
		"leading_party_id": "",
		"model_version": PoliticalBalanceConfig.MODEL_VERSION,
		"config_version": PoliticalBalanceConfig.CONFIG_VERSION
	}

	if party_registry == null:
		return empty_result

	if persona_registry == null:
		return empty_result

	if political_profile == null:
		return empty_result

	if config == null or not config.is_valid():
		return empty_result

	var base_errors := BaseSupportModel.validate(
		base_support,
		constituency_id
	)

	if not base_errors.is_empty():
		return empty_result

	var profile_errors := political_profile.validate(
		persona_registry
	)

	if not profile_errors.is_empty():
		return empty_result

	var responsive := (
		BaseSupportModel.responsive_population(
			base_support
		)
	)

	var potential: Dictionary = {}
	var explanations: Dictionary = {}

	for party_id in party_registry.ids():
		var party := (
			party_registry.get_definition(party_id)
		)

		if party == null:
			continue

		var base := (
			BaseSupportModel.get_support(
				base_support,
				party_id
			)
		)

		var affinity := (
			political_profile.calculate_affinity(
				party,
				persona_registry,
				config
			)
		)

		var value := (
			base
			+ responsive * affinity
		)

		if not is_finite(value):
			return empty_result

		value = max(value, 0.0)

		potential[party_id] = value

		var explanation := PoliticalExplanation.new()

		explanation.constituency_id = constituency_id
		explanation.party_id = party_id
		explanation.base_support = base
		explanation.responsive_population = responsive
		explanation.constituency_affinity = affinity
		explanation.potential = value

		explanations[party_id] = explanation

	var denominator := 0.0

	for party_id in potential.keys():
		denominator += float(
			potential[party_id]
		)

	if denominator <= config.support_tolerance:
		return {
			"support": {},
			"potential": potential,
			"explanations": explanations,
			"leading_party_id": "",
			"model_version": PoliticalBalanceConfig.MODEL_VERSION,
			"config_version": PoliticalBalanceConfig.CONFIG_VERSION
		}

	var support: Dictionary = {}

	var leading_party_id := ""
	var leading_value := -1.0

	for party_id in party_registry.ids():
		if not potential.has(party_id):
			continue

		var normalized := (
			float(potential[party_id])
			/ denominator
		)

		if not is_finite(normalized):
			return empty_result

		normalized = clampf(
			normalized,
			0.0,
			1.0
		)

		support[party_id] = normalized

		var explanation: PoliticalExplanation = (
			explanations[party_id]
		)

		explanation.normalized_support = normalized
		explanation.fingerprint = (
			_build_fingerprint(
				constituency_id,
				party_id,
				base_support,
				political_profile,
				party_registry,
				persona_registry,
				config
			)
		)

		if normalized > leading_value:
			leading_value = normalized
			leading_party_id = party_id

	return {
		"support": support,
		"potential": potential,
		"explanations": explanations,
		"leading_party_id": leading_party_id,
		"model_version": PoliticalBalanceConfig.MODEL_VERSION,
		"config_version": PoliticalBalanceConfig.CONFIG_VERSION
	}


static func _build_fingerprint(
	constituency_id: String,
	party_id: String,
	base_support: Dictionary,
	political_profile: ConstituencyPoliticalProfile,
	party_registry: PartyRegistry,
	persona_registry: PersonaRegistry,
	config: PoliticalBalanceConfig
) -> String:
	var canonical := {
		"model_version": PoliticalBalanceConfig.MODEL_VERSION,
		"config_version": PoliticalBalanceConfig.CONFIG_VERSION,
		"constituency_id": constituency_id,
		"party_id": party_id,
		"base_support": _sorted_dictionary(
			base_support
		),
		"party": (
			party_registry
			.get_definition(party_id)
			.to_dictionary()
		),
		"personas": _canonical_personas(
			political_profile,
			persona_registry
		),
		"config": config.to_dictionary()
	}

	return JSON.stringify(canonical).sha256_text()


static func _canonical_personas(
	profile: ConstituencyPoliticalProfile,
	registry: PersonaRegistry
) -> Array:
	var result: Array = []

	for persona_id in profile.persona_ids():
		var persona := registry.get_definition(
			persona_id
		)

		if persona == null:
			continue

		result.append({
			"persona_id": persona.persona_id,
			"share": profile.get_share(persona_id),
			"definition": persona.to_dictionary()
		})

	return result


static func _sorted_dictionary(
	source: Dictionary
) -> Dictionary:
	var result := {}

	var keys: Array[String] = []

	for key in source.keys():
		keys.append(String(key))

	keys.sort()

	for key in keys:
		result[key] = source[key]

	return result
