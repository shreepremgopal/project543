class_name PoliticalSystem
extends RefCounted


var config: PoliticalBalanceConfig
var state: PoliticalState

var party_registry: PartyRegistry
var persona_registry: PersonaRegistry
var constituency_registry: ConstituencyRegistry


func _init(
	config_value: PoliticalBalanceConfig = null
) -> void:
	config = (
		config_value
		if config_value != null
		else PoliticalBalanceConfig.new()
	)

	state = PoliticalState.new()

	party_registry = PartyRegistry.new()
	persona_registry = PersonaRegistry.new()
	constituency_registry = ConstituencyRegistry.new()


func bind_simulation_state(
	simulation_state: SimulationState
) -> void:
	if simulation_state == null:
		return

	party_registry = simulation_state.parties
	persona_registry = simulation_state.personas
	constituency_registry = simulation_state.constituencies


func calculate_all_bound() -> Dictionary:
	if constituency_registry == null:
		return {}

	return calculate_all(
		constituency_registry,
		party_registry,
		persona_registry
	)



func _init(
	config_value: PoliticalBalanceConfig = null
) -> void:
	config = (
		config_value
		if config_value != null
		else PoliticalBalanceConfig.new()
	)

	state = PoliticalState.new()


func calculate_constituency(
	constituency: Constituency,
	party_registry: PartyRegistry,
	persona_registry: PersonaRegistry
) -> Dictionary:
	if constituency == null:
		return {}

	var profile := (
		ConstituencyPoliticalProfile.from_constituency(
			constituency
		)
	)

	var base_support := (
		_get_constituency_base_support(
			constituency.unique_id,
			party_registry
		)
	)

	var result := (
		PoliticalSupportModel.calculate(
			constituency.unique_id,
			party_registry,
			persona_registry,
			profile,
			base_support,
			config
		)
	)

	if not result.is_empty():
		state.set_result(
			constituency.unique_id,
			result
		)

	return result


func calculate_all(
	constituency_registry: ConstituencyRegistry,
	party_registry: PartyRegistry,
	persona_registry: PersonaRegistry
) -> Dictionary:
	var results := {}

	if constituency_registry == null:
		return results

	for constituency_id in constituency_registry.ids():
		var constituency := (
			constituency_registry.get_constituency(
				constituency_id
			)
		)

		var result := calculate_constituency(
			constituency,
			party_registry,
			persona_registry
		)

		if result.is_empty():
			return {}

		results[
			constituency_id
		] = result

	return results


func poll_constituency(
	constituency_id: String,
	party_id: String,
	tier: PollingModel.Tier,
	seed: int,
	party_registry: PartyRegistry
) -> Dictionary:
	if party_registry == null:
		return {}

	var party_state := (
		party_registry.get_state(
			party_id
		)
	)

	if party_state == null:
		return {}

	if not PollingModel.charge(
		party_state,
		tier,
		config
	):
		return {}

	var truth := state.get_support(
		constituency_id
	)

	if truth.is_empty():
		return {}

	var report := (
		PollingModel.conduct_poll(
			constituency_id,
			state.turn,
			tier,
			truth,
			config,
			seed
		)
	)

	if report.is_empty():
		return {}

	state.information_state.store_report(
		report
	)

	return report


func advance_turn(
	new_turn: int
) -> bool:
	return state.advance_turn(
		new_turn
	)


func get_leader(
	constituency_id: String
) -> String:
	return state.get_leading_party_id(
		constituency_id
	)


func _get_constituency_base_support(
	constituency_id: String,
	party_registry: PartyRegistry
) -> Dictionary:
	var result := {}

	for party_id in party_registry.ids():
		var party_state := (
			party_registry.get_state(
				party_id
			)
		)

		if party_state == null:
			result[party_id] = 0.0
			continue

		result[party_id] = float(
			party_state.base_support.get(
				constituency_id,
				0.0
			)
		)

	return result
