class_name CampaignCoordinator
extends RefCounted

## Canonical end-to-end campaign state.
##
## The coordinator owns orchestration only. Political calculations live in the
## political domain and ElectionEngine; money still moves through the audited
## S6 ledger. The map and UI consume snapshots from this object and never
## mutate simulation state directly.

const CampaignBalanceConfigScript = preload("res://scripts/campaign/campaign_balance_config.gd")
const ElectionEngineScript = preload("res://scripts/election/election_engine.gd")
const ElectionResultScript = preload("res://scripts/election/s7_election_result.gd")
const EconomyStateScript = preload("res://scripts/economy/s6_economy_state.gd")
const EconomyConfigScript = preload("res://scripts/economy/s6_economy_config.gd")
const BusinessScript = preload("res://scripts/economy/s6_business.gd")
const MoneyTransactionScript = preload("res://scripts/economy/s6_money_transaction.gd")
const PoliticalConfigScript = preload("res://scripts/domain/political_balance_config.gd")
const PersonaLoaderScript = preload("res://scripts/data/persona_catalog_loader.gd")
const PersonaRegistryScript = preload("res://scripts/registries/persona_registry.gd")
const ConstituencyRegistryScript = preload("res://scripts/registries/constituency_registry.gd")
const PartyRegistryScript = preload("res://scripts/registries/party_registry.gd")
const PersonaDistributionScript = preload("res://scripts/domain/persona_distribution.gd")
const ConstituencyScript = preload("res://scripts/domain/constituency.gd")
const PartyDefinitionScript = preload("res://scripts/domain/party_definition.gd")
const PartyStateScript = preload("res://scripts/domain/party_state.gd")
const IdeologyProfileScript = preload("res://scripts/domain/ideology_profile.gd")
const PollingModelScript = preload("res://scripts/domain/polling_model.gd")

const SCHEMA_VERSION := 1
const GAME_SEED := 543051
const PLAYER_PARTY_ID := "party_player"
const SETUP_PARTY := "party_setup"
const SETUP_HOME := "home_selection"
const ACTIVE := "active"
const ELECTION_READY := "election_ready"
const COMPLETED := "completed"

var seed: int = GAME_SEED
var config: CampaignBalanceConfig
var political_config: PoliticalBalanceConfig
var economy_config: S6EconomyConfig

var seats: Array = []
var personas: PersonaRegistry
var constituencies: ConstituencyRegistry
var parties: PartyRegistry
var economies: Dictionary = {}

var phase: String = SETUP_PARTY
var turn: int = 1
var actions_used: int = 0
var selected_constituency_id: String = ""
var player_preset_id: String = "party_player"

var local_campaign: Dictionary = {}
var temporary_effects: Array = []
var active_manifestos: Dictionary = {}
var saturation: Dictionary = {}
var scandal_remaining: Dictionary = {}
var fundraised_this_turn: Dictionary = {}
var business_types: Dictionary = {}
var reports: Dictionary = {}
var action_history: Array = []
var event_log: Array = []

var last_projection: S7ElectionResult
var election_result: S7ElectionResult


func _init(seat_data: Array = [], seed_value: int = GAME_SEED) -> void:
	seed = seed_value
	seats = seat_data.duplicate(true)
	config = CampaignBalanceConfigScript.load_json()
	political_config = PoliticalConfigScript.load_json("res://data/political/political_balance_v0_1.json")
	economy_config = EconomyConfigScript.new()
	personas = PersonaRegistryScript.new()
	constituencies = ConstituencyRegistryScript.new()
	parties = PartyRegistryScript.new()


func start_new_campaign(preset_id: String = "party_player", player_name: String = "") -> Dictionary:
	if seats.size() != 543:
		return _failure("INVALID_WORLD", ["Project 543 requires exactly 543 constituencies"])
	if config == null or not config.is_valid():
		return _failure("INVALID_CONFIGURATION", config.validate() if config != null else [])

	var selected_spec := _find_party_spec(preset_id)
	if selected_spec.is_empty():
		selected_spec = _find_party_spec(PLAYER_PARTY_ID)
		preset_id = PLAYER_PARTY_ID

	phase = SETUP_HOME
	turn = 1
	actions_used = 0
	selected_constituency_id = ""
	last_projection = null
	election_result = null
	_build_world(preset_id, player_name.strip_edges().substr(0, 32))
	var world_errors := validate()
	if not world_errors.is_empty():
		return _failure("INVALID_WORLD", world_errors)
	_add_event("campaign", "Choose a home constituency. Your local organisation will begin there.", 1)
	return _success({"phase": phase, "party_id": PLAYER_PARTY_ID})


func confirm_home(constituency_id: String) -> Dictionary:
	if phase != SETUP_HOME:
		return _failure("INVALID_PHASE")
	if not constituencies.has(constituency_id):
		return _failure("INVALID_TARGET", ["Unknown constituency"])

	var player_state := get_party_state(PLAYER_PARTY_ID)
	if player_state == null:
		return _failure("STATE_CORRUPTED")

	player_state.home_constituency_id = constituency_id
	var current_base := float(player_state.base_support.get(constituency_id, 0.0))
	player_state.base_support[constituency_id] = min(1.0, current_base + 0.02)
	phase = ACTIVE
	selected_constituency_id = constituency_id
	turn = 1
	actions_used = 0
	fundraised_this_turn.clear()
	_recalculate_projection()
	_add_event("home", "Home constituency secured: %s. +2% organisational advantage." % constituency_name(constituency_id), turn)
	return _success({"phase": phase, "home_constituency_id": constituency_id})


func select_constituency(constituency_id: String) -> bool:
	if not constituencies.has(constituency_id):
		return false
	selected_constituency_id = constituency_id
	return true


func execute_player_action(action_type: String, target_id: String = "", parameter: String = "") -> Dictionary:
	if phase != ACTIVE:
		return _failure("INVALID_PHASE")
	if actions_used >= int(config.get_value("actions_per_week", 2)):
		return _failure("ACTION_LIMIT_REACHED", ["Two strategic actions are already committed this week"])

	var result := _execute_action(PLAYER_PARTY_ID, action_type, target_id, parameter, true)
	if bool(result.get("ok", false)):
		actions_used += 1
		_recalculate_projection()
		result["actions_remaining"] = max(0, int(config.get_value("actions_per_week", 2)) - actions_used)
	return result


func conduct_poll(target_id: String, tier: int) -> Dictionary:
	if phase != ACTIVE:
		return _failure("INVALID_PHASE")
	if not constituencies.has(target_id):
		return _failure("INVALID_TARGET")
	if tier < int(PollingModel.Tier.BASIC) or tier > int(PollingModel.Tier.DEEP):
		return _failure("INVALID_POLL_TIER")
	var party_state := get_party_state(PLAYER_PARTY_ID)
	var economy: S6EconomyState = economies.get(PLAYER_PARTY_ID)
	if party_state == null or economy == null:
		return _failure("STATE_CORRUPTED")

	var polling_tier = tier
	var cost := PollingModel.cost(polling_tier, political_config)
	if not economy.ledger.spend(
		"poll:%s:%d" % [target_id, turn],
		cost,
		turn,
		"%s polling intelligence" % String(PollingModel.Tier.keys()[polling_tier]),
		MoneyTransactionScript.TYPES.POLLING
	):
		return _failure("INSUFFICIENT_FUNDS", ["A poll costs ₹%s" % _money(cost)])

	var truth := _projection_for(target_id)
	if truth.is_empty():
		economy.ledger.receive(
			"poll:%s:%d:refund" % [target_id, turn],
			cost,
			turn,
			"Polling refund after missing projection",
			MoneyTransactionScript.TYPES.REFUND
		)
		return _failure("STATE_CORRUPTED", ["No current projection exists"])
	var report := PollingModel.conduct_poll(
		target_id,
		turn,
		polling_tier,
		truth.get("support", {}),
		political_config,
		seed
	)
	if report.is_empty():
		economy.ledger.receive(
			"poll:%s:%d:refund" % [target_id, turn],
			cost,
			turn,
			"Polling refund after failed report",
			MoneyTransactionScript.TYPES.REFUND
		)
		return _failure("POLL_FAILED")

	reports[target_id] = report.duplicate(true)
	_sync_party_money(PLAYER_PARTY_ID)
	_add_event("intelligence", "%s poll purchased for ₹%s." % [constituency_name(target_id), _money(cost)], turn)
	return _success({"report": report, "cost": cost})


func resolve_week() -> Dictionary:
	if phase != ACTIVE:
		return _failure("INVALID_PHASE")

	var week_before := turn
	var income: Array = []
	for party_id in parties.ids():
		var economy: S6EconomyState = economies.get(party_id)
		if economy == null:
			continue
		var income_result := economy.collect_income(turn, economy_config)
		_sync_party_money(party_id)
		if int(income_result.get("total_income", 0)) > 0:
			income.append({"party_id": party_id, "amount": int(income_result["total_income"])})

	var ai_actions := _run_ai_turns()
	var risk_changes: Array = []
	for party_id in parties.ids():
		var state := get_party_state(party_id)
		if state == null:
			continue
		var old_risk := state.risk
		if not bool(fundraised_this_turn.get(party_id, false)):
			state.risk = maxf(0.0, state.risk - float(config.get_value("risk_recovery_per_week", 0.02)))
		_sync_party_risk(party_id)
		if not is_equal_approx(old_risk, state.risk):
			risk_changes.append({"party_id": party_id, "before": old_risk, "after": state.risk})

	for party_id in scandal_remaining.keys().duplicate():
		var remaining := maxi(0, int(scandal_remaining[party_id]) - 1)
		if remaining == 0:
			scandal_remaining.erase(party_id)
			_add_event("scandal", "%s has recovered from its financial scandal." % party_name(party_id), turn)
		else:
			scandal_remaining[party_id] = remaining

	_decay_saturation()
	_prune_expired_effects()
	fundraised_this_turn.clear()

	action_history.append({
		"event": "week_resolved",
		"week": week_before,
		"income": income.duplicate(true),
		"ai_actions": ai_actions.duplicate(true),
		"risk_changes": risk_changes.duplicate(true)
	})

	if turn >= int(config.get_value("campaign_weeks", 45)):
		phase = ELECTION_READY
		election_result = _calculate_election()
		last_projection = election_result
		if election_result == null or not election_result.is_valid():
			return _failure("ELECTION_FAILED")
		_add_event("election", "Polling has closed. The 543-seat election is being counted.", turn)
		return _success({
			"week": turn,
			"phase": phase,
			"income": income,
			"ai_actions": ai_actions,
			"election_result": election_result.to_dictionary()
		})

	turn += 1
	actions_used = 0
	_recalculate_projection()
	_add_event("week", "Week %02d begins. Two strategic actions available." % turn, turn)
	return _success({
		"week": turn,
		"phase": phase,
		"income": income,
		"ai_actions": ai_actions,
		"risk_changes": risk_changes
	})


func is_active() -> bool:
	return phase == ACTIVE


func is_election_ready() -> bool:
	return phase == ELECTION_READY or phase == COMPLETED


func get_party_definition(party_id: String) -> PartyDefinition:
	return parties.get_definition(party_id)


func get_party_state(party_id: String) -> PartyState:
	return parties.get_state(party_id)


func party_name(party_id: String) -> String:
	var definition := get_party_definition(party_id)
	return definition.name if definition != null else party_id


func constituency_name(constituency_id: String) -> String:
	var constituency := constituencies.get_constituency(constituency_id)
	return constituency.name if constituency != null else constituency_id


func get_constituency(constituency_id: String) -> Constituency:
	return constituencies.get_constituency(constituency_id)


func get_projection() -> S7ElectionResult:
	return last_projection if last_projection != null else election_result


func get_election_result() -> S7ElectionResult:
	return election_result


func get_constituency_result(constituency_id: String) -> Dictionary:
	return _projection_for(constituency_id).duplicate(true)


func get_report(constituency_id: String) -> Dictionary:
	return reports.get(constituency_id, {}).duplicate(true)


func report_is_stale(constituency_id: String) -> bool:
	var report: Dictionary = reports.get(constituency_id, {})
	if report.is_empty():
		return true
	return turn - int(report.get("turn", -1000)) >= political_config.stale_after_turns


func get_selected_id() -> String:
	return selected_constituency_id


func player_seat_forecast() -> int:
	var projection := get_projection()
	if projection == null:
		return 0
	return int(projection.seat_totals.get(PLAYER_PARTY_ID, 0))


func get_party_colours() -> Dictionary:
	var result := {}
	for party_id in parties.ids():
		var definition := get_party_definition(party_id)
		result[party_id] = Color.from_string(definition.colour, Color.WHITE) if definition != null else Color.WHITE
	return result


func get_map_leaders() -> Dictionary:
	var result := {}
	var projection := get_projection()
	if projection == null:
		return result
	for seat_result in projection.constituency_results:
		result[String(seat_result.get("constituency_id", ""))] = String(seat_result.get("winner_party_id", ""))
	return result


func get_summary() -> Dictionary:
	var player := get_party_state(PLAYER_PARTY_ID)
	var party_definition := get_party_definition(PLAYER_PARTY_ID)
	return {
		"phase": phase,
		"turn": turn,
		"weeks": int(config.get_value("campaign_weeks", 45)),
		"actions_used": actions_used,
		"actions_remaining": max(0, int(config.get_value("actions_per_week", 2)) - actions_used),
		"money": player.money if player != null else 0,
		"followers": player.followers if player != null else 0,
		"risk": player.risk if player != null else 0.0,
		"home_constituency_id": player.home_constituency_id if player != null else "",
		"party_name": party_definition.name if party_definition != null else "",
		"forecast_seats": player_seat_forecast(),
		"majority": 272
	}


func get_active_manifesto() -> Dictionary:
	return active_manifestos.get(PLAYER_PARTY_ID, {}).duplicate(true)


func get_businesses() -> Array:
	var economy: S6EconomyState = economies.get(PLAYER_PARTY_ID)
	if economy == null:
		return []
	var result: Array = []
	for business: S6Business in economy.businesses:
		var item := business.to_dictionary()
		item["type"] = String(business_types.get(PLAYER_PARTY_ID, {}).get(business.business_id, ""))
		result.append(item)
	return result


func get_business_count(business_type: String) -> int:
	return int(business_types.get(PLAYER_PARTY_ID, {}).get(business_type, 0))


func get_event_log(limit: int = 8) -> Array:
	var start := maxi(0, event_log.size() - limit)
	return event_log.slice(start, event_log.size()).duplicate(true)


func validate() -> Array[String]:
	var errors: Array[String] = []
	if config == null:
		errors.append("campaign config is null")
	else:
		errors.append_array(config.validate())
	if constituencies == null or constituencies.size() != 543:
		errors.append("expected exactly 543 constituencies")
	elif personas != null:
		errors.append_array(constituencies.validate(personas))
		for constituency_id in constituencies.ids():
			var constituency := constituencies.get_constituency(constituency_id)
			if constituency == null:
				errors.append("null constituency for %s" % constituency_id)
			else:
				errors.append_array(constituency.validate(personas, true))
	if personas == null or personas.size() != 25:
		errors.append("expected exactly 25 personas")
	else:
		errors.append_array(personas.validate())
	if parties == null or parties.size() < 2:
		errors.append("at least two parties are required")
	else:
		errors.append_array(parties.validate(constituencies))
	var campaign_weeks := int(config.get_value("campaign_weeks", 45)) if config != null else 0
	var action_limit := int(config.get_value("actions_per_week", 2)) if config != null else 0
	if turn < 1 or turn > campaign_weeks:
		errors.append("turn is outside campaign bounds")
	if actions_used < 0 or actions_used > action_limit:
		errors.append("actions_used is outside the weekly action limit")
	if not selected_constituency_id.is_empty() and (constituencies == null or not constituencies.has(selected_constituency_id)):
		errors.append("selected constituency does not exist")
	if parties != null:
		for party_id in parties.ids():
			if not economies.has(party_id):
				errors.append("missing economy for %s" % party_id)
	for party_id in economies.keys():
		var economy: S6EconomyState = economies[party_id]
		if economy == null:
			errors.append("null economy for %s" % party_id)
		else:
			errors.append_array(economy.validate())
	if not [SETUP_PARTY, SETUP_HOME, ACTIVE, ELECTION_READY, COMPLETED].has(phase):
		errors.append("invalid campaign phase")
	if phase == ACTIVE and parties != null:
		var player_state := get_party_state(PLAYER_PARTY_ID)
		if player_state == null or player_state.home_constituency_id.is_empty():
			errors.append("active campaign has no player home constituency")
	if phase in [ELECTION_READY, COMPLETED] and election_result == null:
		errors.append("election-ready campaign has no election result")
	if election_result != null and not election_result.is_valid():
		errors.append_array(election_result.validate())
	return errors


func to_dictionary() -> Dictionary:
	var serialized_economies := {}
	for party_id in economies.keys():
		var economy: S6EconomyState = economies[party_id]
		serialized_economies[String(party_id)] = economy.to_dictionary()
	return {
		"schema_version": SCHEMA_VERSION,
		"model_version": CampaignBalanceConfigScript.MODEL_VERSION,
		"seed": seed,
		"phase": phase,
		"turn": turn,
		"actions_used": actions_used,
		"selected_constituency_id": selected_constituency_id,
		"player_preset_id": player_preset_id,
		"config": config.to_dictionary(),
		"political_config": political_config.to_dictionary(),
		"personas": personas.to_array(),
		"constituencies": constituencies.to_array(),
		"parties": parties.to_array(),
		"economies": serialized_economies,
		"local_campaign": local_campaign.duplicate(true),
		"temporary_effects": temporary_effects.duplicate(true),
		"active_manifestos": active_manifestos.duplicate(true),
		"saturation": saturation.duplicate(true),
		"scandal_remaining": scandal_remaining.duplicate(true),
		"fundraised_this_turn": fundraised_this_turn.duplicate(true),
		"business_types": business_types.duplicate(true),
		"reports": reports.duplicate(true),
		"action_history": action_history.duplicate(true),
		"event_log": event_log.duplicate(true),
		"election_result": election_result.to_dictionary() if election_result != null else {}
	}


static func from_dictionary(seat_data: Array, saved: Dictionary) -> CampaignCoordinator:
	if saved == null or int(saved.get("schema_version", -1)) != SCHEMA_VERSION:
		return null

	var raw_config = saved.get("config", null)
	var raw_political_config = saved.get("political_config", null)
	var raw_personas = saved.get("personas", null)
	var raw_constituencies = saved.get("constituencies", null)
	var raw_parties = saved.get("parties", null)
	var raw_economies = saved.get("economies", null)
	if not raw_config is Dictionary or not raw_political_config is Dictionary:
		return null
	if not raw_personas is Array or not raw_constituencies is Array or not raw_parties is Array:
		return null
	if not raw_economies is Dictionary:
		return null

	var state_fields := [
		"local_campaign",
		"temporary_effects",
		"active_manifestos",
		"saturation",
		"scandal_remaining",
		"fundraised_this_turn",
		"business_types",
		"reports",
		"action_history",
		"event_log"
	]
	for field in state_fields:
		if not saved.has(field):
			return null
	var dictionary_fields := [
		"local_campaign",
		"active_manifestos",
		"saturation",
		"scandal_remaining",
		"fundraised_this_turn",
		"business_types",
		"reports"
	]
	for field in dictionary_fields:
		if not saved[field] is Dictionary:
			return null
	var array_fields := ["temporary_effects", "action_history", "event_log"]
	for field in array_fields:
		if not saved[field] is Array:
			return null
	for item in raw_personas:
		if not item is Dictionary:
			return null
	for item in raw_constituencies:
		if not item is Dictionary:
			return null
	for item in raw_parties:
		if not item is Dictionary:
			return null

	var restored := CampaignCoordinator.new(seat_data, int(saved.get("seed", GAME_SEED)))
	restored.config = CampaignBalanceConfigScript.new(raw_config)
	restored.political_config = PoliticalConfigScript.from_dictionary(raw_political_config)
	restored.personas = PersonaRegistryScript.from_array(raw_personas)
	restored.constituencies = ConstituencyRegistryScript.from_array(raw_constituencies)
	restored.parties = PartyRegistryScript.from_array(raw_parties)
	restored.economies.clear()
	for party_id in raw_economies.keys():
		var economy_data = raw_economies[party_id]
		if not economy_data is Dictionary:
			return null
		if not economy_data.get("ledger", {}) is Dictionary:
			return null
		var ledger_data: Dictionary = economy_data.get("ledger", {})
		if not ledger_data.get("transactions", []) is Array:
			return null
		for transaction_data in ledger_data.get("transactions", []):
			if not transaction_data is Dictionary:
				return null
		if not economy_data.get("businesses", []) is Array:
			return null
		if not economy_data.get("last_fundraising_turn", {}) is Dictionary:
			return null
		for business_data in economy_data.get("businesses", []):
			if not business_data is Dictionary:
				return null
		restored.economies[String(party_id)] = EconomyStateScript.from_dictionary(economy_data)

	restored.phase = String(saved.get("phase", SETUP_PARTY))
	restored.turn = int(saved.get("turn", 1))
	restored.actions_used = int(saved.get("actions_used", 0))
	restored.selected_constituency_id = String(saved.get("selected_constituency_id", ""))
	restored.player_preset_id = String(saved.get("player_preset_id", PLAYER_PARTY_ID))
	restored.local_campaign = saved["local_campaign"].duplicate(true)
	restored.temporary_effects = saved["temporary_effects"].duplicate(true)
	restored.active_manifestos = saved["active_manifestos"].duplicate(true)
	restored.saturation = saved["saturation"].duplicate(true)
	restored.scandal_remaining = saved["scandal_remaining"].duplicate(true)
	restored.fundraised_this_turn = saved["fundraised_this_turn"].duplicate(true)
	restored.business_types = saved["business_types"].duplicate(true)
	restored.reports = saved["reports"].duplicate(true)
	restored.action_history = saved["action_history"].duplicate(true)
	restored.event_log = saved["event_log"].duplicate(true)
	var election_data = saved.get("election_result", {})
	if not election_data is Dictionary:
		return null
	if not election_data.is_empty():
		restored.election_result = ElectionResultScript.from_dictionary(election_data)

	if not restored.validate().is_empty():
		return null
	restored._recalculate_projection()
	return restored

func _build_world(preset_id: String, player_name: String) -> void:
	personas = PersonaLoaderScript.load_json("res://data/personas/persona_catalogue_v0_1.json")
	constituencies = ConstituencyRegistryScript.new()
	parties = PartyRegistryScript.new()
	economies.clear()
	local_campaign.clear()
	temporary_effects.clear()
	active_manifestos.clear()
	saturation.clear()
	scandal_remaining.clear()
	fundraised_this_turn.clear()
	business_types.clear()
	reports.clear()
	action_history.clear()
	event_log.clear()
	player_preset_id = preset_id

	_build_constituencies()
	_build_parties(preset_id, player_name)


func _build_constituencies() -> void:
	var default_turnout := float(config.get_value("default_turnout", 0.68))
	var population_min := int(config.get_value("population_min", 1000000))
	var population_max := int(config.get_value("population_max", 3000000))
	for seat in seats:
		var id := String(seat.get("unique_id", ""))
		if id.is_empty():
			continue
		var h := _hash_int("population|%s|%d" % [id, seed])
		var population := population_min + (h % maxi(1, population_max - population_min + 1))
		var turnout_offset := (int(h / 17) % 1100) - 550
		var turnout := clampf(default_turnout + float(turnout_offset) / 10000.0, 0.50, 0.85)
		var distribution := _build_distribution(id)
		var constituency := ConstituencyScript.new(
			id,
			String(seat.get("ls_seat_name", id)),
			String(seat.get("state_ut_name", "Unknown")),
			String(seat.get("state_ut_code", "")),
			id,
			population,
			turnout,
			true,
			distribution,
			{"source": "Project 543 GIS identity + deterministic gameplay bootstrap", "dataset_status": "replaceable_bootstrap"}
		)
		constituencies.add(constituency)


func _build_parties(preset_id: String, player_name: String) -> void:
	var specs := config.party_specs()
	var raw_support: Dictionary = {}
	var base_total := float(config.get_value("base_support_total", 0.58))
	for constituency_id in constituencies.ids():
		var constituency := constituencies.get_constituency(constituency_id)
		var raw_by_party := {}
		var raw_total := 0.0
		for spec in specs:
			var party_id := String(spec.get("id", ""))
			var hash_value := _hash_int("base|%s|%s|%d" % [party_id, constituency_id, seed])
			var raw := 0.80 + float(hash_value % 1000) / 1000.0 * 0.65
			var home_state := String(spec.get("home_state", ""))
			if not home_state.is_empty() and home_state == constituency.state_ut:
				raw *= 1.75
			raw_by_party[party_id] = raw
			raw_total += raw
		var constituency_support := {}
		for party_id in raw_by_party.keys():
			constituency_support[party_id] = base_total * float(raw_by_party[party_id]) / maxf(raw_total, 0.0001)
		raw_support[constituency_id] = constituency_support

	var player_platform := _find_party_spec(preset_id)
	if player_platform.is_empty():
		player_platform = _find_party_spec(PLAYER_PARTY_ID)
	for spec in specs:
		var party_id := String(spec.get("id", ""))
		var profile_spec: Dictionary = player_platform if party_id == PLAYER_PARTY_ID else spec
		var ideology_data: Dictionary = profile_spec.get("ideology_profile", {})
		var ideology := IdeologyProfileScript.from_dictionary(ideology_data)
		var name := String(profile_spec.get("name", party_id))
		var leader := String(profile_spec.get("leader", "Party Leader"))
		if party_id == PLAYER_PARTY_ID:
			if not player_name.is_empty():
				name = player_name
			leader = "Your campaign"
		var definition := PartyDefinitionScript.new(
			party_id,
			name,
			String(spec.get("colour", "#FFFFFF")),
			leader,
			ideology,
			{"source": "campaign_balance_v0_1.json", "personality": String(spec.get("personality", "player"))}
		)
		var base_support := {}
		for constituency_id in constituencies.ids():
			base_support[constituency_id] = float(raw_support.get(constituency_id, {}).get(party_id, 0.0))
		var home_id := _find_home_for_spec(spec)
		if party_id == PLAYER_PARTY_ID:
			home_id = ""
		var state := PartyStateScript.new(
			party_id,
			int(spec.get("starting_money", int(config.get_value("starting_money", 500000)))),
			int(spec.get("starting_followers", int(config.get_value("starting_followers", 100)))),
			0.0,
			home_id,
			base_support
		)
		if not home_id.is_empty():
			state.base_support[home_id] = min(1.0, float(state.base_support.get(home_id, 0.0)) + 0.02)
		parties.add(definition, state)
		var economy := EconomyStateScript.new(party_id, state.money)
		economies[party_id] = economy
		local_campaign[party_id] = {}
		business_types[party_id] = {}


func _build_distribution(constituency_id: String) -> PersonaDistribution:
	var distribution := PersonaDistributionScript.new()
	var ids := personas.ids()
	var weights: Array = []
	var total_weight := 0
	for persona_id in ids:
		var weight := 1 + (_hash_int("persona|%s|%s|%d" % [constituency_id, persona_id, seed]) % 1000)
		weights.append(weight)
		total_weight += weight
	var assigned := 0
	for index in ids.size():
		var units := PersonaDistributionScript.TOTAL_UNITS - assigned if index == ids.size() - 1 else int(floor(float(weights[index]) / float(maxi(total_weight, 1)) * PersonaDistributionScript.TOTAL_UNITS))
		distribution.set_share(ids[index], units)
		assigned += units
	return distribution


func _find_home_for_spec(spec: Dictionary) -> String:
	var desired_state := String(spec.get("home_state", ""))
	if desired_state.is_empty():
		return ""
	for constituency_id in constituencies.ids():
		if constituencies.get_constituency(constituency_id).state_ut == desired_state:
		return constituency_id
	return ""


func _find_party_spec(party_id: String) -> Dictionary:
	for spec in config.party_specs():
		if String(spec.get("id", "")) == party_id:
			return spec.duplicate(true)
	return {}


func _execute_action(party_id: String, action_type: String, target_id: String, parameter: String, is_player: bool) -> Dictionary:
	var party_state := get_party_state(party_id)
	var economy: S6EconomyState = economies.get(party_id)
	if party_state == null or economy == null:
		return _failure("STATE_CORRUPTED")

	if action_type == "fundraise":
		return _execute_fundraise(party_id, parameter, party_state, economy, is_player)
	if action_type == "business":
		return _execute_business(party_id, parameter, party_state, economy, is_player)
	if action_type == "manifesto":
		return _execute_manifesto(party_id, parameter, party_state, economy, is_player)
	if not ["rally", "interview"].has(action_type):
		return _failure("INVALID_ACTION")
	if not constituencies.has(target_id):
		return _failure("INVALID_TARGET")

	var action := config.action(action_type)
	var cost := int(action.get("cost", 0))
	if not economy.ledger.can_afford(cost):
		return _failure("INSUFFICIENT_FUNDS", ["Requires ₹%s" % _money(cost)])

	var family_key := _saturation_key(party_id, target_id, action_type)
	var saturation_before := float(saturation.get(family_key, 0.0))
	var saturation_multiplier := maxf(
		float(config.get_value("saturation_floor", 0.35)),
		1.0 - float(config.get_value("saturation_step", 0.20)) * saturation_before
	)
	var effect := float(action.get("support_effect", 0.0)) * saturation_multiplier
	if not economy.ledger.spend(
		"campaign:%s:%s" % [action_type, target_id],
		cost,
		turn,
		"%s in %s" % [action_type.capitalize(), constituency_name(target_id)],
		MoneyTransactionScript.TYPES.CAMPAIGN_SPEND
	):
		return _failure("TRANSACTION_REJECTED")

	saturation[family_key] = saturation_before + 1.0
	if action_type == "rally":
		_add_local_modifier(party_id, target_id, effect)
	else:
		temporary_effects.append({
			"effect_id": _action_id(party_id, action_type, target_id),
			"source_action_id": _action_id(party_id, action_type, target_id),
			"party_id": party_id,
			"constituency_id": target_id,
			"magnitude": effect,
			"start_turn": turn,
			"expires_turn": turn + maxi(1, int(action.get("duration", 1))),
			"action_type": action_type
		})
	party_state.followers += int(action.get("followers_gain", 0))
	_sync_party_money(party_id)
	var message := "%s in %s: +%.1f%% local influence%s." % [action_type.capitalize(), constituency_name(target_id), effect * 100.0, " (diminishing returns)" if saturation_before > 0.0 else ""]
	_record_action(party_id, action_type, target_id, cost, effect, saturation_before, is_player, message)
	_add_event("campaign", message, turn)
	return _success({"message": message, "cost": cost, "effect": effect, "target": target_id})


func _execute_manifesto(party_id: String, manifesto_id: String, party_state: PartyState, economy: S6EconomyState, is_player: bool) -> Dictionary:
	var manifesto := config.manifesto(manifesto_id)
	if manifesto.is_empty():
		return _failure("INVALID_MANIFESTO")
	var cost := int(manifesto.get("cost", 0))
	if not economy.ledger.can_afford(cost):
		return _failure("INSUFFICIENT_FUNDS", ["Requires ₹%s" % _money(cost)])
	var saturation_key := _saturation_key(party_id, "__national__", "manifesto")
	var saturation_before := float(saturation.get(saturation_key, 0.0))
	var saturation_multiplier := maxf(float(config.get_value("saturation_floor", 0.35)), 1.0 - float(config.get_value("saturation_step", 0.20)) * saturation_before)
	if not economy.ledger.spend(
		"manifesto:%s" % manifesto_id,
		cost,
		turn,
		"Manifesto launch: %s" % String(manifesto.get("name", manifesto_id)),
		MoneyTransactionScript.TYPES.CAMPAIGN_SPEND
	):
		return _failure("TRANSACTION_REJECTED")

	saturation[saturation_key] = saturation_before + 1.0
	var active := manifesto.duplicate(true)
	active["start_turn"] = turn
	active["expires_turn"] = turn + maxi(1, int(manifesto.get("duration", 1)))
	active["saturation_multiplier"] = saturation_multiplier
	active_manifestos[party_id] = active
	party_state.followers += int(config.action("manifesto").get("followers_gain", 20))
	_sync_party_money(party_id)
	var message := "%s launched for %d weeks. Constituency fit determines its strength." % [String(manifesto.get("name", manifesto_id)), int(manifesto.get("duration", 1))]
	_record_action(party_id, "manifesto", "__national__", cost, float(manifesto.get("support_effect", 0.0)) * saturation_multiplier, saturation_before, is_player, message)
	_add_event("manifesto", message, turn)
	return _success({"message": message, "cost": cost, "manifesto": active})


func _execute_fundraise(party_id: String, amount_text: String, party_state: PartyState, economy: S6EconomyState, is_player: bool) -> Dictionary:
	var requested := int(amount_text)
	var option: Dictionary = {}
	for item in config.fundraising_options():
		if int(item.get("amount", 0)) == requested:
			option = item.duplicate(true)
			break
	if option.is_empty():
		return _failure("INVALID_FUNDRAISING_AMOUNT")
	if bool(fundraised_this_turn.get(party_id, false)):
		return _failure("FUNDRAISING_LIMIT", ["One fundraising drive per turn keeps risk legible"])

	var efficiency := clampf(float(option.get("efficiency", 0.8)), 0.0, 1.0)
	var proceeds := int(floor(float(requested) * efficiency))
	if proceeds <= 0 or not economy.ledger.receive(
		"fundraising:%d" % requested,
		proceeds,
		turn,
		"Fundraising proceeds from requested ₹%s" % _money(requested),
		MoneyTransactionScript.TYPES.FUNDRAISING
	):
		return _failure("TRANSACTION_REJECTED")

	var old_risk := party_state.risk
	var risk_delta := clampf(float(option.get("risk_delta", float(requested) / 5000000.0)), 0.0, 1.0)
	party_state.risk = clampf(party_state.risk + risk_delta, 0.0, 1.0)
	fundraised_this_turn[party_id] = true
	_sync_party_money(party_id)
	_sync_party_risk(party_id)
	var scandal_started := old_risk <= float(config.get_value("risk_scandal_threshold", 0.50)) and party_state.risk > float(config.get_value("risk_scandal_threshold", 0.50))
	if scandal_started:
		scandal_remaining[party_id] = int(config.get_value("risk_scandal_duration", 10))
	var message := "Raised ₹%s from a ₹%s drive. Risk +%.0f%%." % [_money(proceeds), _money(requested), risk_delta * 100.0]
	if scandal_started:
		message += " FINANCIAL SCANDAL: campaign strength halved for 10 weeks."
	_record_action(party_id, "fundraise", "__national__", 0, float(proceeds), old_risk, is_player, message)
	_add_event("fundraising", message, turn)
	return _success({"message": message, "proceeds": proceeds, "risk_delta": risk_delta, "scandal_started": scandal_started})


func _execute_business(party_id: String, business_type: String, party_state: PartyState, economy: S6EconomyState, is_player: bool) -> Dictionary:
	var definition := config.business(business_type)
	if definition.is_empty():
		return _failure("INVALID_BUSINESS")
	var count := int(business_types.get(party_id, {}).get(business_type, 0))
	var limit := int(definition.get("limit", 10))
	if count >= limit:
		return _failure("BUSINESS_LIMIT", ["The %s limit is %d" % [String(definition.get("name", business_type)), limit]])
	var cost := int(definition.get("cost", 0))
	if not economy.ledger.can_afford(cost):
		return _failure("INSUFFICIENT_FUNDS", ["Requires ₹%s" % _money(cost)])
	var id := "%s:%s:%d" % [party_id, business_type, count + 1]
	if not economy.ledger.spend(
		"business:%s" % id,
		cost,
		turn,
		"Constructed %s" % String(definition.get("name", business_type)),
		MoneyTransactionScript.TYPES.CAMPAIGN_SPEND
	):
		return _failure("TRANSACTION_REJECTED")
	var business := BusinessScript.new(
		id,
		party_state.home_constituency_id if not party_state.home_constituency_id.is_empty() else "national",
		cost,
		int(definition.get("income", 0)),
		0.0,
		0.0,
		0.0
	)
	if not economy.add_business(business):
		economy.ledger.receive(
			"business:%s:refund" % id,
			cost,
			turn,
			"Business registration rollback",
			MoneyTransactionScript.TYPES.REFUND
		)
		return _failure("BUSINESS_REGISTRATION_FAILED")
	business_types[party_id][business_type] = count + 1
	_sync_party_money(party_id)
	var message := "%s established. It will return ₹%s each week." % [String(definition.get("name", business_type)), _money(int(definition.get("income", 0)))]
	_record_action(party_id, "business", business_type, cost, float(definition.get("income", 0)), float(count), is_player, message)
	_add_event("economy", message, turn)
	return _success({"message": message, "cost": cost, "business_type": business_type})


func _run_ai_turns() -> Array:
	var actions: Array = []
	var projection := get_projection()
	for party_id in parties.ids():
		if party_id == PLAYER_PARTY_ID:
			continue
		var definition := get_party_definition(party_id)
		var personality := String(definition.provenance.get("personality", "campaigner")) if definition != null else "campaigner"
		for slot in 2:
			var action_type := "interview"
			var target := _best_ai_target(party_id, personality, projection)
			var parameter := ""
			var economy: S6EconomyState = economies.get(party_id)
			var state := get_party_state(party_id)
			if economy == null or state == null:
				continue
			if (personality == "economic" and turn <= 12) or (target.is_empty() and _can_afford_business(party_id, "food_stall")):
				action_type = "business"
				parameter = _best_affordable_business(party_id)
			elif not economy.ledger.can_afford(int(config.action("rally").get("cost", 100000))) and state.risk < 0.80:
				action_type = "fundraise"
				parameter = "250000"
			elif personality in ["aggressive", "regional", "campaigner"]:
				action_type = "rally"
			else:
				action_type = "interview"
			if action_type in ["rally", "interview"] and target.is_empty():
				target = _fallback_target()
			var result := _execute_action(party_id, action_type, target, parameter, false)
			if bool(result.get("ok", false)):
				actions.append({"party_id": party_id, "action_type": action_type, "target": target, "message": String(result.get("message", ""))})
			projection = get_projection()
	return actions


func _best_ai_target(party_id: String, personality: String, projection: S7ElectionResult) -> String:
	if projection == null:
		return _fallback_target()
	var best_id := ""
	var best_score := -INF
	for seat_result in projection.constituency_results:
		var id := String(seat_result.get("constituency_id", ""))
		var support: Dictionary = seat_result.get("support", {})
		var own := float(support.get(party_id, 0.0))
		var rivals: Array = []
		for rival_id in parties.ids():
			if rival_id != party_id:
				rivals.append(float(support.get(rival_id, 0.0)))
		rivals.sort()
		var strongest_rival := float(rivals[-1]) if not rivals.is_empty() else 0.0
		var gap := strongest_rival - own
		var closeness := 1.0 / (0.015 + absf(gap))
		var score := closeness + (maxf(0.0, gap) * 2.0)
		var constituency := constituencies.get_constituency(id)
		if personality == "regional" and constituency != null and constituency.state_ut == "Uttar Pradesh":
			score *= 1.35
		if personality == "economic" and constituency != null and constituency.state_ut in ["Gujarat", "Maharashtra", "Karnataka"]:
			score *= 1.15
		if score > best_score:
			best_score = score
			best_id = id
	return best_id if not best_id.is_empty() else _fallback_target()


func _calculate_election() -> S7ElectionResult:
	var state := _campaign_state_snapshot()
	return ElectionEngineScript.resolve(
		constituencies,
		parties,
		personas,
		political_config,
		state,
		turn,
		float(config.get_value("eligibility_factor", 0.65))
	)


func _recalculate_projection() -> void:
	if parties == null or parties.size() == 0 or constituencies == null or constituencies.size() == 0:
		return
	last_projection = _calculate_election()


func _projection_for(constituency_id: String) -> Dictionary:
	var projection := get_projection()
	if projection == null:
		return {}
	for result in projection.constituency_results:
		if String(result.get("constituency_id", "")) == constituency_id:
		return result
	return {}


func _campaign_state_snapshot() -> Dictionary:
	return {
		"seed": seed,
		"local_modifiers": local_campaign.duplicate(true),
		"temporary_effects": temporary_effects.duplicate(true),
		"active_manifestos": active_manifestos.duplicate(true),
		"scandal_remaining": scandal_remaining.duplicate(true),
		"risk_scandal_modifier": float(config.get_value("risk_scandal_modifier", 0.50))
	}


func _add_local_modifier(party_id: String, target_id: String, amount: float) -> void:
	if not local_campaign.has(party_id):
		local_campaign[party_id] = {}
	local_campaign[party_id][target_id] = float(local_campaign[party_id].get(target_id, 0.0)) + amount


func _record_action(party_id: String, action_type: String, target_id: String, cost: int, effect: float, saturation_before: float, is_player: bool, message: String) -> void:
	action_history.append({
		"action_id": _action_id(party_id, action_type, target_id),
		"party_id": party_id,
		"action_type": action_type,
		"target": target_id,
		"turn": turn,
		"cost": cost,
		"effect": effect,
		"saturation_before": saturation_before,
		"is_player": is_player,
		"message": message
	})


func _add_event(event_type: String, message: String, event_turn: int) -> void:
	event_log.append({"type": event_type, "turn": event_turn, "message": message})
	if event_log.size() > 80:
		event_log.pop_front()


func _action_id(party_id: String, action_type: String, target_id: String) -> String:
	return "%s-W%02d-%s-%s" % [party_id, turn, action_type, target_id]


func _saturation_key(party_id: String, target_id: String, family: String) -> String:
	return "%s|%s|%s" % [party_id, target_id, family]


func _decay_saturation() -> void:
	var decay := float(config.get_value("saturation_decay", 0.50))
	for key in saturation.keys():
		saturation[key] = maxf(0.0, float(saturation[key]) - decay)


func _prune_expired_effects() -> void:
	var retained: Array = []
	for effect in temporary_effects:
		if int(effect.get("expires_turn", 0)) > turn:
			retained.append(effect)
	temporary_effects = retained
	for party_id in active_manifestos.keys().duplicate():
		if int(active_manifestos[party_id].get("expires_turn", 0)) <= turn:
			active_manifestos.erase(party_id)


func _sync_party_money(party_id: String) -> void:
	var state := get_party_state(party_id)
	var economy: S6EconomyState = economies.get(party_id)
	if state != null and economy != null:
		state.money = economy.ledger.balance


func _sync_party_risk(party_id: String) -> void:
	var state := get_party_state(party_id)
	if state != null:
		state.risk = clampf(state.risk, 0.0, 1.0)


func _can_afford_business(party_id: String, business_type: String) -> bool:
	var economy: S6EconomyState = economies.get(party_id)
	var definition := config.business(business_type)
	return economy != null and not definition.is_empty() and economy.ledger.can_afford(int(definition.get("cost", 0)))


func _best_affordable_business(party_id: String) -> String:
	var selected := ""
	var best_income := -1
	var economy: S6EconomyState = economies.get(party_id)
	if economy == null:
		return selected
	for definition in config.businesses():
		var id := String(definition.get("id", ""))
		var count := int(business_types.get(party_id, {}).get(id, 0))
		if count >= int(definition.get("limit", 10)):
			continue
		if economy.ledger.can_afford(int(definition.get("cost", 0))) and int(definition.get("income", 0)) > best_income:
			best_income = int(definition.get("income", 0))
			selected = id
	return selected


func _fallback_target() -> String:
	var ids := constituencies.ids()
	return ids[0] if not ids.is_empty() else ""


func _find_business_type(party_id: String, business_id: String) -> String:
	return String(business_types.get(party_id, {}).get(business_id, ""))


func _hash_int(value: String) -> int:
	var digest := value.sha256_text().substr(0, 8)
	var result := 0
	for character in digest:
		var digit := "0123456789abcdef".find(character)
		if digit >= 0:
			result = result * 16 + digit
	return abs(result)


func _money(value: int) -> String:
	var text := str(value)
	var output := ""
	var count := 0
	for index in range(text.length() - 1, -1, -1):
		output = text[index] + output
		count += 1
		if count == 3 and index > 0:
			output = "," + output
			count = 0
	return output


func _success(extra: Dictionary = {}) -> Dictionary:
	var result := {"ok": true, "code": "OK"}
	for key in extra.keys():
		result[key] = extra[key]
	return result


func _failure(code: String, errors: Array = []) -> Dictionary:
	return {"ok": false, "code": code, "errors": errors}
