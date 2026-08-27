extends SceneTree

var failures: int = 0

func _initialize() -> void:
	_test_ideology()
	_test_persona_catalogue()
	_test_distribution()
	_test_constituency()
	_test_party()
	_test_fixture_round_trip()
	_test_ledger()

	if failures == 0:
		print("SPRINT 4 PASS: all domain tests passed.")
		quit(0)
	else:
		push_error("SPRINT 4 FAILURE: %s test(s) failed." % failures)
		quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _test_ideology() -> void:
	var valid := IdeologyProfile.new(-1.0, 1.0, 0.0, 0.5, -0.5, 1.0)
	_check(valid.is_valid(), "valid ideology profile rejected")

	var invalid_low := IdeologyProfile.new(-1.01, 0.0, 0.0, 0.0, 0.0, 0.0)
	_check(not invalid_low.is_valid(), "ideology below -1 accepted")

	var invalid_high := IdeologyProfile.new(1.01, 0.0, 0.0, 0.0, 0.0, 0.0)
	_check(not invalid_high.is_valid(), "ideology above +1 accepted")

	var round_trip := IdeologyProfile.from_dictionary(valid.to_dictionary())
	_check(valid.equals(round_trip), "ideology serialization round-trip changed value")

func _test_persona_catalogue() -> void:
	var names := [
		"Economic Growth Focused",
		"Welfare Focused",
		"Public Services Focused",
		"Low-Tax Focused",
		"Employment Focused",
		"Infrastructure Focused",
		"Governance Reform Focused",
		"Stability Focused",
		"Anti-Corruption Focused",
		"Environmental Focused",
		"Rural Development Focused",
		"Urban Development Focused",
		"Small Business Focused",
		"Industrial Growth Focused",
		"Social Reform Focused",
		"Traditional Values Focused",
		"Education Focused",
		"Healthcare Focused",
		"National Development Focused",
		"Local Development Focused",
		"Cost-of-Living Focused",
		"Technology & Innovation Focused",
		"Public Safety Focused",
		"Balanced Policy",
		"Protest / Change Focused"
	]
	var registry := PersonaRegistry.new()
	for index in names.size():
		var id := "persona_%02d" % (index + 1)
		var definition := PersonaDefinition.new(
			id,
			names[index],
			IdeologyProfile.new(),
			{},
			false,
			false
		)
		_check(registry.add(definition), "failed to add %s" % id)
	_check(registry.size() == 25, "persona registry does not contain exactly 25 definitions")
	_check(registry.validate().is_empty(), "persona registry validation failed")

func _test_distribution() -> void:
	var registry := PersonaRegistry.new()
	for index in 25:
		registry.add(PersonaDefinition.new("p_%02d" % (index + 1), "P%02d" % (index + 1)))

	var distribution := PersonaDistribution.new()
	for index in 25:
		distribution.set_share("p_%02d" % (index + 1), 400)
	_check(distribution.total_units() == 10000, "distribution did not total 10000 units")
	_check(distribution.is_valid(registry), "valid distribution rejected")

	distribution.set_share("p_01", 401)
	_check(not distribution.is_valid(registry), "distribution above total accepted")

func _test_constituency() -> void:
	var constituency := Constituency.new(
		"C-001",
		"Test Constituency",
		"Test State",
		"TS",
		"C-001",
		1000,
		0.70,
		true
	)
	_check(constituency.is_valid(), "valid incomplete constituency rejected")

	var invalid := Constituency.new(
		"C-002",
		"Invalid",
		"Test State",
		"TS",
		"C-002",
		-1
	)
	_check(not invalid.is_valid(), "negative population accepted")

func _test_party() -> void:
	var party := PartyDefinition.new(
		"party_a",
		"Party A",
		"#000000",
		"Leader A",
		IdeologyProfile.new()
	)
	var state := PartyState.new(
		"party_a",
		500000,
		100,
		0.0,
		"",
		{}
	)
	var registry := PartyRegistry.new()
	_check(registry.add(party, state), "valid party rejected")
	_check(registry.validate().is_empty(), "party registry validation failed")

func _test_fixture_round_trip() -> void:
	var original := PoliticalFixture.build_foundation_fixture()
	var errors := original.validate()
	_check(errors.is_empty(), "foundation fixture invalid: %s" % [errors])
	var restored := SimulationState.from_dictionary(original.to_dictionary())
	_check(
		original.to_dictionary() == restored.to_dictionary(),
		"simulation state serialization round-trip changed state"
	)

func _test_ledger() -> void:
	var change := PoliticalStateChange.new(
		"campaign",
		"rally",
		5,
		"FIXTURE-001",
		"support",
		0.01,
		"rally_local_support"
	)
	_check(change.validate().is_empty(), "valid state ledger entry rejected")
