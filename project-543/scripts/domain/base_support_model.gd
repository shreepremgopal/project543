class_name BaseSupportModel
extends RefCounted


static func validate(
	base_support: Dictionary,
	constituency_id: String = ""
) -> Array[String]:
	var errors: Array[String] = []
	var total := 0.0

	for party_id in base_support.keys():
		var id := String(party_id)
		var value := float(base_support[party_id])

		if not is_finite(value):
			errors.append(
				"Base support '%s' is not finite"
				% id
			)
			continue

		if value < 0.0 or value > 1.0:
			errors.append(
				"Base support '%s'=%s; expected [0,1]"
				% [id, value]
			)

		total += value

	if total > 1.0 + 0.000001:
		errors.append(
			"Base support total for '%s'=%s; maximum is 1.0"
			% [constituency_id, total]
		)

	return errors


static func total(
	base_support: Dictionary
) -> float:
	var result := 0.0

	for party_id in base_support.keys():
		var value := float(
			base_support[party_id]
		)

		if is_finite(value):
			result += max(value, 0.0)

	return result


static func responsive_population(
	base_support: Dictionary
) -> float:
	return 1.0 - total(base_support)


static func get_support(
	base_support: Dictionary,
	party_id: String
) -> float:
	return float(
		base_support.get(party_id, 0.0)
	)
