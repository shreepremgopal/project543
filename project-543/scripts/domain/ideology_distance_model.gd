class_name IdeologyDistanceModel
extends RefCounted


static func calculate(
	party_profile: IdeologyProfile,
	persona_profile: IdeologyProfile,
	salience: Dictionary
) -> float:
	if party_profile == null or persona_profile == null:
		return 0.0

	var weighted_squared_distance := 0.0

	for dimension in IdeologyProfile.DIMENSIONS:
		var weight := float(
			salience.get(dimension, 0.0)
		)

		var difference := (
			party_profile.get_value(dimension)
			- persona_profile.get_value(dimension)
		)

		weighted_squared_distance += (
			weight
			* difference
			* difference
		)

	return 0.5 * sqrt(
		max(weighted_squared_distance, 0.0)
	)


static func validate_salience(
	salience: Dictionary,
	tolerance: float = 0.000001
) -> Array[String]:
	var errors: Array[String] = []

	var total := 0.0

	for dimension in IdeologyProfile.DIMENSIONS:
		if not salience.has(dimension):
			errors.append(
				"Missing salience dimension '%s'"
				% dimension
			)
			continue

		var value := float(salience[dimension])

		if not is_finite(value):
			errors.append(
				"Salience '%s' is not finite"
				% dimension
			)
		elif value < 0.0:
			errors.append(
				"Salience '%s' is negative"
				% dimension
			)
		else:
			total += value

	for key in salience.keys():
		if not IdeologyProfile.DIMENSIONS.has(
			String(key)
		):
			errors.append(
				"Unknown salience dimension '%s'"
				% String(key)
			)

	if abs(total - 1.0) > tolerance:
		errors.append(
			"Salience total=%s; expected 1.0"
			% total
		)

	return errors
