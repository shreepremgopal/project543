class_name Sprint5PoliticalFixture
extends RefCounted


static func ideology(
	economic: float,
	welfare: float,
	social: float,
	governance: float,
	environment: float,
	national: float
) -> IdeologyProfile:
	return IdeologyProfile.new(
		economic,
		welfare,
		social,
		governance,
		environment,
		national
	)


static func uniform_salience() -> Dictionary:
	return {
		"economic_policy": 1.0 / 6.0,
		"welfare": 1.0 / 6.0,
		"social_policy": 1.0 / 6.0,
		"governance": 1.0 / 6.0,
		"environment": 1.0 / 6.0,
		"national_policy": 1.0 / 6.0
	}


static func persona(
	id: String,
	profile: IdeologyProfile,
	weights: Dictionary = {}
) -> PersonaDefinition:
	var actual_weights := (
		weights
		if not weights.is_empty()
		else uniform_salience()
	)

	return PersonaDefinition.new(
		id,
		id,
		profile,
		actual_weights,
		true,
		false,
		0.0,
		{"source": "Sprint 5 deterministic fixture"}
	)


static func party(
	id: String,
	profile: IdeologyProfile
) -> PartyDefinition:
	return PartyDefinition.new(
		id,
		id,
		"#808080",
		"Test Leader",
		profile,
		{"source": "Sprint 5 deterministic fixture"}
	)


static func distribution(
	shares: Dictionary
) -> PersonaDistribution:
	var result := PersonaDistribution.new()

	var total := 0

	for key in shares.keys():
		var units := int(shares[key])
		result.set_share(
			String(key),
			units
		)
		total += units

	if total != PersonaDistribution.TOTAL_UNITS:
		push_error(
			"Fixture distribution total=%s"
			% total
		)

	return result
