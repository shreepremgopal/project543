class_name S6CampaignState
extends RefCounted

const SCHEMA_VERSION: int = 1

var schema_version: int = SCHEMA_VERSION

var effects: Array[S6CampaignEffect] = []
var saturation: S6SaturationState = S6SaturationState.new()
var risk_exposure: Array[S6RiskExposure] = []


func add_effect(effect: S6CampaignEffect) -> bool:
	if effect == null:
		return false

	if not effect.is_valid():
		return false

	if has_effect(effect.effect_id):
		return false

	effects.append(effect)
	return true


func has_effect(effect_id: String) -> bool:
	for effect: S6CampaignEffect in effects:
		if effect.effect_id == effect_id:
			return true

	return false


func remove_expired(current_turn: int) -> void:
	var retained: Array[S6CampaignEffect] = []

	for effect: S6CampaignEffect in effects:
		if effect.permanent or effect.is_active(current_turn):
			retained.append(effect)

	effects = retained


func get_active_effects(
	party_id: String,
	constituency_id: String,
	current_turn: int
) -> Array[S6CampaignEffect]:
	var result: Array[S6CampaignEffect] = []

	for effect: S6CampaignEffect in effects:
		if effect.party_id != party_id:
			continue

		if effect.constituency_id != constituency_id:
			continue

		if effect.is_active(current_turn):
			result.append(effect)

	return result


func add_risk_exposure(
	party_id: String,
	constituency_id: String,
	amount: float,
	config: S6EconomyConfig
) -> bool:
	if not is_finite(amount) or amount <= 0.0:
		return false

	if party_id.strip_edges().is_empty():
		return false

	if constituency_id.strip_edges().is_empty():
		return false

	if config == null:
		return false

	var current: float = get_risk_exposure(
		party_id,
		constituency_id
	)

	var next_value: float = min(
		config.risk_exposure_cap,
		current + amount
	)

	for exposure: S6RiskExposure in risk_exposure:
		if (
			exposure.party_id == party_id
			and exposure.constituency_id == constituency_id
		):
			exposure.amount = next_value
			return true

	risk_exposure.append(
		S6RiskExposure.new(
			party_id,
			constituency_id,
			next_value
		)
	)

	return true


func get_risk_exposure(
	party_id: String,
	constituency_id: String
) -> float:
	for exposure: S6RiskExposure in risk_exposure:
		if (
			exposure.party_id == party_id
			and exposure.constituency_id == constituency_id
		):
			return exposure.amount

	return 0.0


func validate() -> Array[String]:
	var errors: Array[String] = []

	if schema_version != SCHEMA_VERSION:
		errors.append("unsupported campaign schema version")

	if saturation == null:
		errors.append("saturation is null")
	else:
		errors.append_array(saturation.validate())

	var effect_ids: Dictionary = {}

	for effect: S6CampaignEffect in effects:
		if effect == null:
			errors.append("null campaign effect")
			continue

		errors.append_array(effect.validate())

		if effect_ids.has(effect.effect_id):
			errors.append(
				"duplicate effect_id: %s"
				% effect.effect_id
			)

		effect_ids[effect.effect_id] = true

	for exposure: S6RiskExposure in risk_exposure:
		if exposure == null:
			errors.append("null risk exposure")
			continue

		errors.append_array(exposure.validate())

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func to_dictionary() -> Dictionary:
	var serialized_effects: Array = []

	for effect: S6CampaignEffect in effects:
		serialized_effects.append(
			effect.to_dictionary()
		)

	var serialized_risk: Array = []

	for exposure: S6RiskExposure in risk_exposure:
		serialized_risk.append(
			exposure.to_dictionary()
		)

	return {
		"schema_version": schema_version,
		"effects": serialized_effects,
		"saturation": saturation.to_dictionary(),
		"risk_exposure": serialized_risk
	}


static func from_dictionary(data: Dictionary) -> S6CampaignState:
	var result: S6CampaignState = S6CampaignState.new()

	result.schema_version = int(
		data.get(
			"schema_version",
			SCHEMA_VERSION
		)
	)

	var effect_data: Array = data.get("effects", [])

	for item: Variant in effect_data:
		if item is Dictionary:
			result.effects.append(
				S6CampaignEffect.from_dictionary(
					item as Dictionary
				)
			)

	var saturation_data: Variant = data.get(
		"saturation",
		{}
	)

	if saturation_data is Dictionary:
		result.saturation = S6SaturationState.from_dictionary(
			saturation_data as Dictionary
		)

	var risk_data: Array = data.get(
		"risk_exposure",
		[]
	)

	for item: Variant in risk_data:
		if item is Dictionary:
			result.risk_exposure.append(
				S6RiskExposure.from_dictionary(
					item as Dictionary
				)
			)

	return result
