class_name Sprint5BalanceLab
extends RefCounted


static func run(
	persona_registry: PersonaRegistry,
	party_registry: PartyRegistry,
	config: PoliticalBalanceConfig
) -> Array[String]:
	var failures: Array[String] = []

	if persona_registry == null:
		failures.append(
			"Balance lab received null persona registry"
		)
		return failures

	if party_registry == null:
		failures.append(
			"Balance lab received null party registry"
		)
		return failures

	var lambda_values := [
		0.5,
		1.0,
		2.0,
		3.0,
		4.0
	]

	for lambda_value in lambda_values:
		var test_config := (
			PoliticalBalanceConfig.from_dictionary(
				config.to_dictionary()
			)
		)

		test_config.alignment_lambda = (
			lambda_value
		)

		if not test_config.is_valid():
			failures.append(
				"Invalid balance config for lambda=%s"
				% lambda_value
			)

	var base_values := [
		0.0,
		0.25,
		0.50,
		0.99
	]

	for base in base_values:
		var valid := BaseSupportModel.validate(
			{"party_a": base}
		)

		if not valid.is_empty():
			failures.append(
				"Valid base support rejected: %s"
				% base
			)

	var invalid := BaseSupportModel.validate(
		{
			"party_a": 0.75,
			"party_b": 0.30
		}
	)

	if invalid.is_empty():
		failures.append(
			"Base support > 1.0 was accepted"
		)

	return failures
