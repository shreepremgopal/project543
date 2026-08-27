class_name PoliticalFixture
extends RefCounted

static func build_foundation_fixture() -> SimulationState:
	var state := SimulationState.new()

	var persona_names := [
		["persona_01", "Economic Growth Focused"],
		["persona_02", "Welfare Focused"],
		["persona_03", "Public Services Focused"],
		["persona_04", "Low-Tax Focused"],
		["persona_05", "Employment Focused"],
		["persona_06", "Infrastructure Focused"],
		["persona_07", "Governance Reform Focused"],
		["persona_08", "Stability Focused"],
		["persona_09", "Anti-Corruption Focused"],
		["persona_10", "Environmental Focused"],
		["persona_11", "Rural Development Focused"],
		["persona_12", "Urban Development Focused"],
		["persona_13", "Small Business Focused"],
		["persona_14", "Industrial Growth Focused"],
		["persona_15", "Social Reform Focused"],
		["persona_16", "Traditional Values Focused"],
		["persona_17", "Education Focused"],
		["persona_18", "Healthcare Focused"],
		["persona_19", "National Development Focused"],
		["persona_20", "Local Development Focused"],
		["persona_21", "Cost-of-Living Focused"],
		["persona_22", "Technology & Innovation Focused"],
		["persona_23", "Public Safety Focused"],
		["persona_24", "Balanced Policy"],
		["persona_25", "Protest / Change Focused"]
	]

	for item in persona_names:
		var definition := PersonaDefinition.new(
			String(item[0]),
			String(item[1]),
			IdeologyProfile.new(),
			{},
			false,
			false,
			0.0,
			{"source": "GDD V0.1", "approval_status": "identity_approved_values_unresolved"}
		)
		state.personas.add(definition)

	var distribution := PersonaDistribution.new()
	distribution.set_share("persona_01", 400)
	distribution.set_share("persona_02", 400)
	distribution.set_share("persona_03", 400)
	distribution.set_share("persona_04", 400)
	distribution.set_share("persona_05", 400)
	distribution.set_share("persona_06", 400)
	distribution.set_share("persona_07", 400)
	distribution.set_share("persona_08", 400)
	distribution.set_share("persona_09", 400)
	distribution.set_share("persona_10", 400)
	distribution.set_share("persona_11", 400)
	distribution.set_share("persona_12", 400)
	distribution.set_share("persona_13", 400)
	distribution.set_share("persona_14", 400)
	distribution.set_share("persona_15", 400)
	distribution.set_share("persona_16", 400)
	distribution.set_share("persona_17", 400)
	distribution.set_share("persona_18", 400)
	distribution.set_share("persona_19", 400)
	distribution.set_share("persona_20", 400)
	distribution.set_share("persona_21", 400)
	distribution.set_share("persona_22", 400)
	distribution.set_share("persona_23", 400)
	distribution.set_share("persona_24", 400)
	distribution.set_share("persona_25", 400)

	var constituency := Constituency.new(
		"FIXTURE-001",
		"Foundation Test Constituency",
		"TEST",
		"TST",
		"FIXTURE-001",
		1000000,
		0.70,
		true,
		distribution,
		{"source": "Sprint 4 Scenario Pack", "approval_status": "test_fixture"}
	)
	state.constituencies.add(constituency)

	var party_definition := PartyDefinition.new(
		"party_fixture",
		"Foundation Test Party",
		"#808080",
		"Test Leader",
		IdeologyProfile.new(),
		{"source": "Sprint 4 Scenario Pack", "approval_status": "test_fixture"}
	)
	var party_state := PartyState.new(
		"party_fixture",
		500000,
		100,
		0.0,
		"FIXTURE-001",
		{"FIXTURE-001": 0.10}
	)
	state.parties.add(party_definition, party_state)

	return state
