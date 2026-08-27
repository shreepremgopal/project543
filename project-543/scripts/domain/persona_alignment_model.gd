class_name PersonaAlignmentModel
extends RefCounted


static func calculate(
	party_profile: IdeologyProfile,
	persona: PersonaDefinition,
	config: PoliticalBalanceConfig
) -> float:
	if party_profile == null or persona == null:
		return 0.0

	if not party_profile.is_valid():
		return 0.0

	if not persona.ideology_profile.is_valid():
		return 0.0

	var salience_errors := (
		IdeologyDistanceModel.validate_salience(
			persona.priority_weights,
			config.salience_tolerance
		)
	)

	if not salience_errors.is_empty():
		return 0.0

	var distance := IdeologyDistanceModel.calculate(
		party_profile,
		persona.ideology_profile,
		persona.priority_weights
	)

	var alignment := exp(
		-config.alignment_lambda
		* distance
		* distance
	)

	return clampf(alignment, 0.0, 1.0)
