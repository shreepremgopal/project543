class_name CampaignBalanceConfig
extends RefCounted

## Data-driven campaign rules for the player-facing 45-week campaign.
## The JSON file is the tuning surface; these defaults keep fixtures resilient
## when a config is loaded in isolation.

const MODEL_VERSION := "campaign-v0.1"
const CONFIG_VERSION := "campaign-config-v0.1"
const CONFIG_PATH := "res://data/campaign/campaign_balance_v0_1.json"

var data: Dictionary = {}


func _init(source: Dictionary = {}) -> void:
	data = _defaults()
	_merge_dictionary(data, source)


func validate() -> Array[String]:
	var errors: Array[String] = []
	var weeks := int(data.get("campaign_weeks", 0))
	var actions := int(data.get("actions_per_week", 0))
	var eligibility := float(data.get("eligibility_factor", -1.0))
	var population_min := int(data.get("population_min", 0))
	var population_max := int(data.get("population_max", 0))

	if weeks <= 0:
		errors.append("campaign_weeks must be greater than zero")
	if actions <= 0:
		errors.append("actions_per_week must be greater than zero")
	if not _ratio(eligibility):
		errors.append("eligibility_factor must be in [0, 1]")
	if population_min <= 0 or population_max < population_min:
		errors.append("population range is invalid")

	var action_data = data.get("actions", {})
	if not action_data is Dictionary:
		errors.append("actions must be a Dictionary")
	else:
		for action_type in ["rally", "interview", "manifesto"]:
			var raw_action = action_data.get(action_type, {})
			if not raw_action is Dictionary:
				errors.append("%s definition must be a Dictionary" % action_type)
				continue
			var action: Dictionary = raw_action
			if int(action.get("cost", 0)) <= 0:
				errors.append("%s cost must be greater than zero" % action_type)
			if float(action.get("support_effect", 0.0)) <= 0.0 and action_type != "manifesto":
				errors.append("%s support_effect must be greater than zero" % action_type)
			if int(action.get("duration", 0)) < 0:
				errors.append("%s duration must not be negative" % action_type)

	var businesses := data.get("businesses", [])
	if not businesses is Array:
		errors.append("businesses must be an Array")
	elif businesses.is_empty():
		errors.append("at least one business definition is required")
	else:
		for raw_business in businesses:
			if not raw_business is Dictionary:
				errors.append("business definition must be a Dictionary")
				continue
			var business: Dictionary = raw_business
			if int(business.get("cost", 0)) <= 0:
				errors.append("business cost must be greater than zero")
			if int(business.get("income", 0)) < 0:
				errors.append("business income must not be negative")
			if int(business.get("limit", 0)) <= 0:
				errors.append("business limit must be greater than zero")

	var risk_threshold := float(data.get("risk_scandal_threshold", -1.0))
	var risk_recovery := float(data.get("risk_recovery_per_week", -1.0))
	if not _ratio(risk_threshold):
		errors.append("risk_scandal_threshold must be in [0, 1]")
	if not _ratio(risk_recovery):
		errors.append("risk_recovery_per_week must be in [0, 1]")

	var manifesto_data := data.get("manifestos", [])
	if not manifesto_data is Array or manifesto_data.is_empty():
		errors.append("at least one manifesto definition is required")
	else:
		for raw_manifesto in manifesto_data:
			if not raw_manifesto is Dictionary:
				errors.append("manifesto definition must be a Dictionary")
				continue
			var manifesto: Dictionary = raw_manifesto
			if String(manifesto.get("id", "")).strip_edges().is_empty():
				errors.append("manifesto id must not be empty")
			if int(manifesto.get("cost", 0)) <= 0:
				errors.append("manifesto cost must be greater than zero")

	var party_data := data.get("parties", [])
	if not party_data is Array or party_data.size() < 2:
		errors.append("at least two party definitions are required")
	else:
		for raw_party in party_data:
			if not raw_party is Dictionary:
				errors.append("party definition must be a Dictionary")
				continue
			var party: Dictionary = raw_party
			if String(party.get("id", "")).strip_edges().is_empty():
				errors.append("party id must not be empty")
			if not party.get("ideology_profile", {}) is Dictionary:
				errors.append("party ideology_profile must be a Dictionary")

	var fundraising_data := data.get("fundraising", [])
	if not fundraising_data is Array or fundraising_data.is_empty():
		errors.append("at least one fundraising definition is required")
	else:
		for raw_option in fundraising_data:
			if not raw_option is Dictionary:
				errors.append("fundraising definition must be a Dictionary")
				continue
			var option: Dictionary = raw_option
			if int(option.get("amount", 0)) <= 0:
				errors.append("fundraising amount must be greater than zero")
			if not _ratio(float(option.get("efficiency", -1.0))):
				errors.append("fundraising efficiency must be in [0, 1]")
			if not _ratio(float(option.get("risk_delta", -1.0))):
				errors.append("fundraising risk_delta must be in [0, 1]")

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func action(action_type: String) -> Dictionary:
	var actions = data.get("actions", {})
	if not actions is Dictionary:
		return {}
	var value = actions.get(action_type, {})
	return value.duplicate(true) if value is Dictionary else {}


func business(business_type: String) -> Dictionary:
	for item in businesses():
		if item is Dictionary and String(item.get("id", "")) == business_type:
			return item.duplicate(true)
	return {}


func businesses() -> Array:
	var value = data.get("businesses", [])
	return value.duplicate(true) if value is Array else []


func manifesto(manifesto_id: String) -> Dictionary:
	for item in manifestos():
		if item is Dictionary and String(item.get("id", "")) == manifesto_id:
			return item.duplicate(true)
	return {}


func manifestos() -> Array:
	var value = data.get("manifestos", [])
	return value.duplicate(true) if value is Array else []


func party_specs() -> Array:
	var value = data.get("parties", [])
	return value.duplicate(true) if value is Array else []


func fundraising_options() -> Array:
	var value = data.get("fundraising", [])
	return value.duplicate(true) if value is Array else []


func get_value(key: String, fallback: Variant = null) -> Variant:
	return data.get(key, fallback)


func to_dictionary() -> Dictionary:
	var result := data.duplicate(true)
	result["model_version"] = MODEL_VERSION
	result["config_version"] = CONFIG_VERSION
	return result


static func load_json(path: String = CONFIG_PATH) -> CampaignBalanceConfig:
	if not FileAccess.file_exists(path):
		push_warning("Campaign config missing; using built-in defaults: " + path)
		return CampaignBalanceConfig.new()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Campaign config could not be opened; using defaults: " + path)
		return CampaignBalanceConfig.new()

	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	if error != OK or typeof(parser.data) != TYPE_DICTIONARY:
		push_warning("Campaign config is invalid; using built-in defaults")
		return CampaignBalanceConfig.new()

	return CampaignBalanceConfig.new(parser.data)


func _defaults() -> Dictionary:
	return {
		"schema_version": 1,
		"model_version": MODEL_VERSION,
		"config_version": CONFIG_VERSION,
		"campaign_weeks": 45,
		"actions_per_week": 2,
		"starting_money": 500000,
		"starting_followers": 100,
		"eligibility_factor": 0.65,
		"default_turnout": 0.68,
		"population_min": 1000000,
		"population_max": 3000000,
		"base_support_total": 0.58,
		"risk_scandal_threshold": 0.50,
		"risk_scandal_duration": 10,
		"risk_scandal_modifier": 0.50,
		"risk_recovery_per_week": 0.02,
		"saturation_step": 0.20,
		"saturation_floor": 0.35,
		"saturation_decay": 0.50,
		"actions": {
			"rally": {"cost": 100000, "support_effect": 0.010, "duration": 0, "followers_gain": 12},
			"interview": {"cost": 50000, "support_effect": 0.005, "duration": 3, "followers_gain": 4},
			"manifesto": {"cost": 75000, "support_effect": 0.025, "duration": 8, "followers_gain": 20}
		},
		"fundraising": [
			{"amount": 100000, "efficiency": 0.80, "risk_delta": 0.02},
			{"amount": 250000, "efficiency": 0.80, "risk_delta": 0.05},
			{"amount": 500000, "efficiency": 0.80, "risk_delta": 0.10},
			{"amount": 1000000, "efficiency": 0.80, "risk_delta": 0.20}
		],
		"businesses": [
			{"id": "food_stall", "name": "Food Stall", "cost": 20000, "income": 2000, "limit": 10, "description": "A modest but reliable local income stream."},
			{"id": "water_supply", "name": "Water Supply", "cost": 50000, "income": 5000, "limit": 10, "description": "A dependable utility investment."},
			{"id": "hotel", "name": "Hotel", "cost": 100000, "income": 10000, "limit": 10, "description": "Balanced growth with a clear ten-week payback."},
			{"id": "farmland", "name": "Farmland", "cost": 500000, "income": 50000, "limit": 10, "description": "Large capital commitment with strong recurring income."},
			{"id": "large_business", "name": "Large Business", "cost": 1000000, "income": 100000, "limit": 10, "description": "A national-scale investment for a mature campaign."}
		],
		"manifestos": [
			{"id": "infrastructure_first", "name": "Infrastructure First", "cost": 75000, "duration": 8, "support_effect": 0.025, "focus_personas": ["persona_06", "persona_11", "persona_12", "persona_19"], "description": "Prioritises roads, connectivity and visible national development."},
			{"id": "people_first", "name": "People First", "cost": 75000, "duration": 8, "support_effect": 0.025, "focus_personas": ["persona_02", "persona_03", "persona_17", "persona_18", "persona_21"], "description": "Puts welfare, services, education and healthcare at the centre."},
			{"id": "clean_government", "name": "Clean Government", "cost": 75000, "duration": 8, "support_effect": 0.025, "focus_personas": ["persona_07", "persona_09", "persona_20", "persona_23"], "description": "A reform platform for voters who want accountable institutions."},
			{"id": "green_transition", "name": "Green Transition", "cost": 75000, "duration": 8, "support_effect": 0.025, "focus_personas": ["persona_10", "persona_11", "persona_22"], "description": "Pairs environmental stewardship with technology and rural resilience."}
		],
		"parties": [
			{"id": "party_player", "name": "National Reform", "leader": "Campaign Director", "colour": "#3B82F6", "personality": "player", "starting_money": 500000, "starting_followers": 100, "home_state": "", "ideology_profile": {"economic_policy": -0.15, "welfare": 0.20, "social_policy": -0.10, "governance": 0.30, "environment": 0.20, "national_policy": 0.25}},
			{"id": "party_development", "name": "Development Front", "leader": "Arjun Mehta", "colour": "#F97316", "personality": "economic", "starting_money": 700000, "starting_followers": 500, "home_state": "Gujarat", "ideology_profile": {"economic_policy": 0.35, "welfare": -0.05, "social_policy": 0.20, "governance": 0.05, "environment": -0.15, "national_policy": 0.35}},
			{"id": "party_people", "name": "People's Coalition", "leader": "Meera Das", "colour": "#22C55E", "personality": "regional", "starting_money": 650000, "starting_followers": 650, "home_state": "Uttar Pradesh", "ideology_profile": {"economic_policy": -0.25, "welfare": 0.40, "social_policy": 0.10, "governance": -0.05, "environment": 0.30, "national_policy": -0.05}},
			{"id": "party_civic", "name": "Civic Alliance", "leader": "Kabir Sen", "colour": "#A855F7", "personality": "campaigner", "starting_money": 600000, "starting_followers": 450, "home_state": "Kerala", "ideology_profile": {"economic_policy": 0.05, "welfare": 0.10, "social_policy": -0.25, "governance": 0.40, "environment": 0.05, "national_policy": 0.00}}
		]
	}


func _merge_dictionary(destination: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		var value = source[key]
		if value is Dictionary and destination.get(key) is Dictionary:
			_merge_dictionary(destination[key], value)
		else:
			destination[key] = value


func _ratio(value: float) -> bool:
	return is_finite(value) and value >= 0.0 and value <= 1.0
