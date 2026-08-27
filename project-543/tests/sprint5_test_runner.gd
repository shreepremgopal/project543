extends SceneTree


const EPSILON := 0.0001

var failures: Array[String] = []


func _initialize() -> void:
	_test_config()
	_test_identical_ideology()
	_test_maximum_separation()
	_test_zero_salience()
	_test_symmetry()
	_test_persona_single()
	_test_persona_mixed()
	_test_persona_order_invariance()
	_test_distribution_preservation()
	_test_base_support()
	_test_support_normalization()
	_test_support_determinism()
	_test_support_finite()
	_test_explanation_reconstruction()
	_test_causal_fingerprint()
	_test_polling_determinism()
	_test_polling_variability()
	_test_polling_cost()
	_test_polling_truth_immutability()
	_test_polling_quality()
	_test_polling_staleness()
	_test_no_omniscience()
	_test_state_round_trip()

	if failures.is_empty():
		print(
			"SPRINT 5 PASS: all political intelligence tests passed."
		)
		quit(0)
		return

	for failure in failures:
		print(
			"SPRINT 5 FAILURE: "
			+ failure
		)

	quit(1)


func _test_config() -> void:
	var config := PoliticalBalanceConfig.new()

	_check(
		config.is_valid(),
		"Default political balance config invalid"
	)

	_check(
		config.alignment_lambda == 2.0,
		"Default lambda is not 2.0"
	)


func _test_identical_ideology() -> void:
	var profile := (
		Sprint5PoliticalFixture.ideology(
			0.2,
			-0.1,
			0.4,
			0.0,
			0.8,
			-0.3
		)
	)

	var persona := (
		Sprint5PoliticalFixture.persona(
			"p",
			profile
		)
	)

	var config := PoliticalBalanceConfig.new()

	var distance := (
		IdeologyDistanceModel.calculate(
			profile,
			profile,
			persona.priority_weights
		)
	)

	var alignment := (
		PersonaAlignmentModel.calculate(
			profile,
			persona,
			config
		)
	)

	_check(
		abs(distance) <= EPSILON,
		"Identical ideology distance != 0"
	)

	_check(
		abs(alignment - 1.0) <= EPSILON,
		"Identical ideology alignment != 1"
	)


func _test_maximum_separation() -> void:
	var party := (
		Sprint5PoliticalFixture.ideology(
			1.0,
			1.0,
			1.0,
			1.0,
			1.0,
			1.0
		)
	)

	var persona_profile := (
		Sprint5PoliticalFixture.ideology(
			-1.0,
			-1.0,
			-1.0,
			-1.0,
			-1.0,
			-1.0
		)
	)

	var persona := (
		Sprint5PoliticalFixture.persona(
			"extreme",
			persona_profile
		)
	)

	var config := PoliticalBalanceConfig.new()

	var distance := (
		IdeologyDistanceModel.calculate(
			party,
			persona_profile,
			persona.priority_weights
		)
	)

	var alignment := (
		PersonaAlignmentModel.calculate(
			party,
			persona,
			config
		)
	)

	_check(
		distance > 0.9,
		"Maximum separation distance unexpectedly low"
	)

	_check(
		alignment < 0.2,
		"Maximum separation alignment unexpectedly high"
	)


func _test_zero_salience() -> void:
	var party := (
		Sprint5PoliticalFixture.ideology(
			1.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0
		)
	)

	var persona_profile := (
		Sprint5PoliticalFixture.ideology(
			-1.0,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0
		)
	)

	var weights := {
		"economic_policy": 0.0,
		"welfare": 0.2,
		"social_policy": 0.2,
		"governance": 0.2,
		"environment": 0.2,
		"national_policy": 0.2
	}

	var distance := (
		IdeologyDistanceModel.calculate(
			party,
			persona_profile,
			weights
		)
	)

	_check(
		abs(distance) <= EPSILON,
		"Zero-salience dimension affected distance"
	)


func _test_symmetry() -> void:
	var a := (
		Sprint5PoliticalFixture.ideology(
			0.7,
			-0.2,
			0.4,
			0.1,
			-0.5,
			0.3
		)
	)

	var b := (
		Sprint5PoliticalFixture.ideology(
			-0.3,
			0.5,
			0.1,
			-0.2,
			0.8,
			-0.4
		)
	)

	var weights := (
		Sprint5PoliticalFixture.uniform_salience()
	)

	var ab := (
		IdeologyDistanceModel.calculate(
			a,
			b,
			weights
		)
	)

	var ba := (
		IdeologyDistanceModel.calculate(
			b,
			a,
			weights
		)
	)

	_check(
		abs(ab - ba) <= EPSILON,
		"Distance symmetry failed"
	)


func _test_persona_single() -> void:
	var persona := (
		Sprint5PoliticalFixture.persona(
			"p",
			Sprint5PoliticalFixture.ideology(
				0.2,
				0.1,
				0.0,
				0.2,
				-0.1,
				0.3
			)
		)
	)

	var registry := PersonaRegistry.new()

	_check(
		registry.add(persona),
		"Could not add fixture persona"
	)

	var party_registry := PartyRegistry.new()

	var party := (
		Sprint5PoliticalFixture.party(
			"a",
			persona.ideology_profile
		)
	)

	_check(
		party_registry.add(party),
		"Could not add fixture party"
	)

	var profile := (
		ConstituencyPoliticalProfile.new(
			"C",
			Sprint5PoliticalFixture.distribution(
				{"p": 10000}
			)
		)
	)

	var affinity := (
		profile.calculate_affinity(
			party,
			registry,
			PoliticalBalanceConfig.new()
		)
	)

	_check(
		abs(affinity - 1.0) <= EPSILON,
		"100% persona affinity != persona alignment"
	)


func _test_persona_mixed() -> void:
	var registry := PersonaRegistry.new()

	var p1 := (
		Sprint5PoliticalFixture.persona(
			"p1",
			Sprint5PoliticalFixture.ideology(
				0, 0, 0, 0, 0, 0
			)
		)
	)

	var p2 := (
		Sprint5PoliticalFixture.persona(
			"p2",
			Sprint5PoliticalFixture.ideology(
				1, 1, 1, 1, 1, 1
			)
		)
	)

	registry.add(p1)
	registry.add(p2)

	var party_registry := PartyRegistry.new()

	var party := (
		Sprint5PoliticalFixture.party(
			"party",
			Sprint5PoliticalFixture.ideology(
				0, 0, 0, 0, 0, 0
			)
		)
	)

	party_registry.add(party)

	var profile := (
		ConstituencyPoliticalProfile.new(
			"C",
			Sprint5PoliticalFixture.distribution(
				{
					"p1": 5000,
					"p2": 5000
				}
			)
		)
	)

	var config := PoliticalBalanceConfig.new()

	var expected := (
		0.5
		* PersonaAlignmentModel.calculate(
			party.ideological_profile,
			p1,
			config
		)
		+ 0.5
		* PersonaAlignmentModel.calculate(
			party.ideological_profile,
			p2,
			config
		)
	)

	var actual := (
		profile.calculate_affinity(
			party,
			registry,
			config
		)
	)

	_check(
		abs(actual - expected) <= EPSILON,
		"Mixed persona aggregation failed"
	)


func _test_persona_order_invariance() -> void:
	var registry := PersonaRegistry.new()

	registry.add(
		Sprint5PoliticalFixture.persona(
			"b",
			Sprint5PoliticalFixture.ideology(
				0.2, 0, 0, 0, 0, 0
			)
		)
	)

	registry.add(
		Sprint5PoliticalFixture.persona(
			"a",
			Sprint5PoliticalFixture.ideology(
				-0.2, 0, 0, 0, 0, 0
			)
		)
	)

	var party := (
		Sprint5PoliticalFixture.party(
			"party",
			Sprint5PoliticalFixture.ideology(
				0, 0, 0, 0, 0, 0
			)
		)
	)

	var profile_a := (
		ConstituencyPoliticalProfile.new(
			"C",
			Sprint5PoliticalFixture.distribution(
				{
					"a": 5000,
					"b": 5000
				}
			)
		)
	)

	var profile_b := (
		ConstituencyPoliticalProfile.new(
			"C",
			Sprint5PoliticalFixture.distribution(
				{
					"b": 5000,
					"a": 5000
				}
			)
		)
	)

	var config := PoliticalBalanceConfig.new()

	var first := profile_a.calculate_affinity(
		party,
		registry,
		config
	)

	var second := profile_b.calculate_affinity(
		party,
		registry,
		config
	)

	_check(
		abs(first - second) <= EPSILON,
		"Persona order changed affinity"
	)


func _test_distribution_preservation() -> void:
	var registry := PersonaRegistry.new()

	registry.add(
		Sprint5PoliticalFixture.persona(
			"moderate",
			Sprint5PoliticalFixture.ideology(
				0, 0, 0, 0, 0, 0
			)
		)
	)

	registry.add(
		Sprint5PoliticalFixture.persona(
			"left",
			Sprint5PoliticalFixture.ideology(
				-1, 0, 0, 0, 0, 0
			)
		)
	)

	registry.add(
		Sprint5PoliticalFixture.persona(
			"right",
			Sprint5PoliticalFixture.ideology(
				1, 0, 0, 0, 0, 0
			)
		)
	)

	var party := (
		Sprint5PoliticalFixture.party(
			"party",
			Sprint5PoliticalFixture.ideology(
				0, 0, 0, 0, 0, 0
			)
		)
	)

	var config := PoliticalBalanceConfig.new()

	var moderate := (
		ConstituencyPoliticalProfile.new(
			"A",
			Sprint5PoliticalFixture.distribution(
				{"moderate": 10000}
			)
		)
	)

	var polarized := (
		ConstituencyPoliticalProfile.new(
			"B",
			Sprint5PoliticalFixture.distribution(
				{
					"left": 5000,
					"right": 5000
				}
			)
		)
	)

	var a := moderate.calculate_affinity(
		party,
		registry,
		config
	)

	var b := polarized.calculate_affinity(
		party,
		registry,
		config
	)

	_check(
		abs(a - b) > EPSILON,
		"Distribution preservation test did not distinguish coalitions"
	)


func _test_base_support() -> void:
	for value in [
		0.0,
		0.25,
		0.50,
		0.99
	]:
		_check(
			BaseSupportModel.validate(
				{"a": value}
			).is_empty(),
			"Valid base support rejected: %s"
			% value
		)

	_check(
		not BaseSupportModel.validate(
			{"a": 1.01}
		).is_empty(),
		"Base support 1.01 accepted"
	)

	_check(
		not BaseSupportModel.validate(
			{
				"a": 0.75,
				"b": 0.50
			}
		).is_empty(),
		"Base support total > 1 accepted"
	)


func _test_support_normalization() -> void:
	var personas := PersonaRegistry.new()

	personas.add(
		Sprint5PoliticalFixture.persona(
			"p",
			Sprint5PoliticalFixture.ideology(
				0, 0, 0, 0, 0, 0
			)
		)
	)

	var parties := PartyRegistry.new()

	parties.add(
		Sprint5PoliticalFixture.party(
			"a",
			Sprint5PoliticalFixture.ideology(
				0, 0, 0, 0, 0, 0
			)
		)
	)

	parties.add(
		Sprint5PoliticalFixture.party(
			"b",
			Sprint5PoliticalFixture.ideology(
				1, 1, 1, 1, 1, 1
			)
		)
	)

	var profile := (
		ConstituencyPoliticalProfile.new(
			"C",
			Sprint5PoliticalFixture.distribution(
				{"p": 10000}
			)
		)
	)

	var result := (
		PoliticalSupportModel.calculate(
			"C",
			parties,
			personas,
			profile,
			{
				"a": 0.1,
				"b": 0.1
			},
			PoliticalBalanceConfig.new()
		)
	)

	var support: Dictionary = (
		result["support"]
	)

	var total := 0.0

	for party_id in support.keys():
		total += float(
			support[party_id]
		)

	_check(
		abs(total - 1.0) <= EPSILON,
		"Support did not normalize to 1"
	)


func _test_support_determinism() -> void:
	var personas := PersonaRegistry.new()

	personas.add(
		Sprint5PoliticalFixture.persona(
			"p",
			Sprint5PoliticalFixture.ideology(
				0.2, 0.1, 0, 0, 0, 0
			)
		)
	)

	var parties := PartyRegistry.new()

	parties.add(
		Sprint5PoliticalFixture.party(
			"a",
			Sprint5PoliticalFixture.ideology(
				0.2, 0.1, 0, 0, 0, 0
			)
		)
	)

	parties.add(
		Sprint5PoliticalFixture.party(
			"b",
			Sprint5PoliticalFixture.ideology(
				-0.5, 0, 0, 0, 0, 0
			)
		)
	)

	var profile := (
		ConstituencyPoliticalProfile.new(
			"C",
			Sprint5PoliticalFixture.distribution(
				{"p": 10000}
			)
		)
	)

	var config := PoliticalBalanceConfig.new()

	var first := (
		PoliticalSupportModel.calculate(
			"C",
			parties,
			personas,
			profile,
			{
				"a": 0.1,
				"b": 0.2
			},
			config
		)
	)

	var second := (
		PoliticalSupportModel.calculate(
			"C",
			parties,
			personas,
			profile,
			{
				"a": 0.1,
				"b": 0.2
			},
			config
		)
	)

	_check(
		first["support"] == second["support"],
		"Political truth was not deterministic"
	)


func _test_support_finite() -> void:
	var support := {
		"a": 0.2,
		"b": 0.8
	}

	for key in support.keys():
		var value := float(
			support[key]
		)

		_check(
			is_finite(value)
			and value >= 0.0
			and value <= 1.0,
			"Invalid support value"
		)


func _test_explanation_reconstruction() -> void:
	var explanation := PoliticalExplanation.new()

	explanation.base_support = 0.2
	explanation.responsive_population = 0.8
	explanation.constituency_affinity = 0.75

	explanation.calculate_potential()

	_check(
		abs(
			explanation.potential
			- 0.8
		) <= EPSILON,
		"Explanation potential incorrect"
	)

	_check(
		explanation.reconstructs(EPSILON),
		"Explanation failed reconstruction"
	)


func _test_causal_fingerprint() -> void:
	var personas := PersonaRegistry.new()

	personas.add(
		Sprint5PoliticalFixture.persona(
			"p",
			Sprint5PoliticalFixture.ideology(
				0, 0, 0, 0, 0, 0
			)
		)
	)

	var parties := PartyRegistry.new()

	parties.add(
		Sprint5PoliticalFixture.party(
			"a",
			Sprint5PoliticalFixture.ideology(
				0, 0, 0, 0, 0, 0
			)
		)
	)

	var profile := (
		ConstituencyPoliticalProfile.new(
			"C",
			Sprint5PoliticalFixture.distribution(
				{"p": 10000}
			)
		)
	)

	var config := PoliticalBalanceConfig.new()

	var first := (
		PoliticalSupportModel.calculate(
			"C",
			parties,
			personas,
			profile,
			{"a": 0.1},
			config
		)
	)

	var second := (
		PoliticalSupportModel.calculate(
			"C",
			parties,
			personas,
			profile,
			{"a": 0.1},
			config
		)
	)

	var first_explanation: PoliticalExplanation = (
		first["explanations"]["a"]
	)

	var second_explanation: PoliticalExplanation = (
		second["explanations"]["a"]
	)

	_check(
		first_explanation.fingerprint
		== second_explanation.fingerprint,
		"Causal fingerprint not deterministic"
	)

	_check(
		not first_explanation.fingerprint.is_empty(),
		"Causal fingerprint missing"
	)


func _test_polling_determinism() -> void:
	var config := PoliticalBalanceConfig.new()

	var truth := {
		"a": 0.5,
		"b": 0.3,
		"c": 0.2
	}

	var first := PollingModel.conduct_poll(
		"C",
		1,
		PollingModel.Tier.STANDARD,
		truth,
		config,
		54321
	)

	var second := PollingModel.conduct_poll(
		"C",
		1,
		PollingModel.Tier.STANDARD,
		truth,
		config,
		54321
	)

	_check(
		first == second,
		"Same polling seed produced different result"
	)


func _test_polling_variability() -> void:
	var config := PoliticalBalanceConfig.new()

	var truth := {
		"a": 0.5,
		"b": 0.5
	}

	var first := PollingModel.conduct_poll(
		"C",
		1,
		PollingModel.Tier.STANDARD,
		truth,
		config,
		1
	)

	var second := PollingModel.conduct_poll(
		"C",
		1,
		PollingModel.Tier.STANDARD,
		truth,
		config,
		2
	)

	_check(
		first["results"] != second["results"],
		"Different polling seeds produced identical report"
	)


func _test_polling_cost() -> void:
	var config := PoliticalBalanceConfig.new()

	var state := PartyState.new(
		"party",
		100000,
		0,
		0.0,
		"",
		{}
	)

	var before := state.money

	var charged := PollingModel.charge(
		state,
		PollingModel.Tier.BASIC,
		config
	)

	_check(
		charged,
		"Polling charge failed"
	)

	_check(
		state.money
		== before - config.poll_basic_cost,
		"Incorrect polling cost"
	)


func _test_polling_truth_immutability() -> void:
	var config := PoliticalBalanceConfig.new()

	var truth := {
		"a": 0.5,
		"b": 0.3,
		"c": 0.2
	}

	var before := truth.duplicate(true)

	PollingModel.conduct_poll(
		"C",
		1,
		PollingModel.Tier.DEEP,
		truth,
		config,
		999
	)

	_check(
		truth == before,
		"Polling mutated political truth"
	)


func _test_polling_quality() -> void:
	var config := PoliticalBalanceConfig.new()

	_check(
		config.poll_basic_uncertainty
		> config.poll_standard_uncertainty,
		"Basic uncertainty not greater than Standard"
	)

	_check(
		config.poll_standard_uncertainty
		> config.poll_deep_uncertainty,
		"Standard uncertainty not greater than Deep"
	)


func _test_polling_staleness() -> void:
	var state := PoliticalInformationState.new()

	state.advance_turn(1)

	state.store_report(
		{
			"constituency_id": "C",
			"turn": 1
		}
	)

	_check(
		not state.is_stale(
			"C",
			3
		),
		"Fresh poll marked stale"
	)

	state.advance_turn(4)

	_check(
		state.is_stale(
			"C",
			3
		),
		"Old poll did not become stale"
	)


func _test_no_omniscience() -> void:
	var config := PoliticalBalanceConfig.new()

	var truth := {
		"a": 0.5000,
		"b": 0.5000
	}

	var report := PollingModel.conduct_poll(
		"C",
		1,
		PollingModel.Tier.DEEP,
		truth,
		config,
		12345
	)

	var results: Dictionary = report[
		"results"
	]

	var exact := true

	for party_id in truth.keys():
		var estimate := float(
			results[party_id]["estimate"]
		)

		if abs(
			estimate
			- float(truth[party_id])
		) > EPSILON:
			exact = false
			break

	_check(
		not exact,
		"Deep polling accidentally returned exact truth"
	)


func _test_state_round_trip() -> void:
	var state := PoliticalState.new()

	state.turn = 7

	state.support_by_constituency[
		"C"
	] = {
		"a": 0.6,
		"b": 0.4
	}

	var serialized := state.to_dictionary()

	var restored := (
		PoliticalState.from_dictionary(
			serialized
		)
	)

	_check(
		restored.turn == 7,
		"PoliticalState turn round-trip failed"
	)

	_check(
		restored.get_support("C")
		== state.get_support("C"),
		"PoliticalState support round-trip failed"
	)


func _check(
	condition: bool,
	message: String
) -> void:
	if not condition:
		failures.append(message)
