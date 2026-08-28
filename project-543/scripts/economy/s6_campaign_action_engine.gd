class_name S6CampaignActionEngine
extends RefCounted

static func execute(
	action: S6CampaignAction,
	economy: S6EconomyState,
	campaign: S6CampaignState,
	turn: int,
	target_vulnerability: float,
	config: S6EconomyConfig
) -> Dictionary:
	var result := {
		"success": false,
		"reason": "",
		"party_id": "",
		"constituency_id": "",
		"action_id": "",
		"action_type": "",
		"cost": 0,
		"influence": 0.0,
		"saturation_before": 0.0,
		"saturation_after": 0.0,
		"risk_exposure": 0.0,
		"risk_class": "",
		"effects": []
	}

	if action == null:
		result["reason"] = "action is null"
		return result

	result["action_id"] = action.action_id
	result["party_id"] = action.party_id
	result["constituency_id"] = action.constituency_id
	result["action_type"] = action.action_type

	if economy == null:
		result["reason"] = "economy is null"
		return result

	if campaign == null:
		result["reason"] = "campaign is null"
		return result

	if config == null or not config.is_valid():
		result["reason"] = "invalid economy config"
		return result

	if turn < 1:
		result["reason"] = "turn must be >= 1"
		return result

	if action.party_id != economy.party_id:
		result["reason"] = "party mismatch"
		return result

	if not is_finite(target_vulnerability):
		result["reason"] = "target vulnerability is not finite"
		return result

	if target_vulnerability < 0.0 or target_vulnerability > 1.0:
		result["reason"] = "target vulnerability must be in [0, 1]"
		return result

	if not action.is_valid(config):
		result["reason"] = "invalid campaign action"
		return result

	var cost := int(
		ceil(
			float(action.base_cost)
			* action.intensity
		)
	)

	if cost <= 0:
		result["reason"] = "calculated campaign cost invalid"
		return result

	if not economy.ledger.can_afford(cost):
		result["reason"] = "insufficient funds"
		return result

	var saturation_before := campaign.saturation.get_value(
		action.party_id,
		action.constituency_id,
		action.action_family()
	)

	var saturation_multiplier := campaign.saturation.calculate_multiplier(
		action.party_id,
		action.constituency_id,
		action.action_family(),
		config
	)

	var base_influence := config.action_base_influence(
		action.action_type
	)

	if base_influence <= 0.0:
		result["reason"] = "unsupported campaign action type"
		return result

	var intensity_efficiency := sqrt(action.intensity)

	var target_factor := 0.75 + (
		1.0 - target_vulnerability
	) * 0.25

	var raw_influence := (
		base_influence
		* intensity_efficiency
		* saturation_multiplier
		* target_factor
		* action.saturation_response
	)

	var risk_profile := S6RiskProfile.new(
		action.risk,
		target_vulnerability,
		campaign.get_risk_exposure(
			action.party_id,
			action.constituency_id
		)
	)

	if not risk_profile.is_valid():
		result["reason"] = "invalid risk profile"
		return result

	var new_risk := risk_profile.calculate_exposure()
	var risk_class := risk_profile.classify(config)

	var risk_penalty := 1.0

	match risk_class:
		S6RiskProfile.LOW:
			risk_penalty = 1.00
		S6RiskProfile.MEDIUM:
			risk_penalty = 0.95
		S6RiskProfile.HIGH:
			risk_penalty = 0.85

	var influence := raw_influence * risk_penalty

	if influence <= 0.0:
		result["reason"] = "calculated influence invalid"
		return result

	if not economy.ledger.spend(
		"campaign:%s" % action.action_id,
		cost,
		turn,
		"Campaign action %s in constituency %s"
		% [
			action.action_type,
			action.constituency_id
		],
		S6MoneyTransaction.TYPES.CAMPAIGN_SPEND
	):
		result["reason"] = "campaign expenditure rejected"
		return result

	var effect_id := _effect_id(
		action,
		turn
	)

	var permanent := action.duration == 0

	var effect := S6CampaignEffect.new(
		effect_id,
		action.action_id,
		action.party_id,
		action.constituency_id,
		action.action_type,
		influence,
		turn,
		action.duration,
		permanent,
		{
			"model_version": S6EconomyConfig.MODEL_VERSION,
			"config_version": S6EconomyConfig.CONFIG_VERSION,
			"cost": cost,
			"saturation_before": saturation_before,
			"saturation_multiplier": saturation_multiplier,
			"risk_exposure": new_risk,
			"risk_class": risk_class
		}
	)

	if not effect.is_valid():
		# Roll back the spend through the explicit refund mechanism.
		economy.ledger.receive(
			"campaign:%s:refund" % action.action_id,
			cost,
			turn,
			"Campaign action validation rollback",
			S6MoneyTransaction.TYPES.REFUND
		)

		result["reason"] = "generated effect invalid"
		return result

	if not campaign.add_effect(effect):
		economy.ledger.receive(
			"campaign:%s:refund" % action.action_id,
			cost,
			turn,
			"Campaign effect registration rollback",
			S6MoneyTransaction.TYPES.REFUND
		)

		result["reason"] = "effect registration failed"
		return result

	if not campaign.saturation.apply(
		action.party_id,
		action.constituency_id,
		action.action_family(),
		action.saturation_response
	):
		economy.ledger.receive(
			"campaign:%s:refund" % action.action_id,
			cost,
			turn,
			"Campaign saturation rollback",
			S6MoneyTransaction.TYPES.REFUND
		)

		result["reason"] = "saturation update failed"
		return result

	if not campaign.add_risk_exposure(
		action.party_id,
		action.constituency_id,
		new_risk,
		config
	):
		economy.ledger.receive(
			"campaign:%s:refund" % action.action_id,
			cost,
			turn,
			"Campaign risk rollback",
			S6MoneyTransaction.TYPES.REFUND
		)

		result["reason"] = "risk update failed"
		return result

	var saturation_after := campaign.saturation.get_value(
		action.party_id,
		action.constituency_id,
		action.action_family()
	)

	result["success"] = true
	result["reason"] = "campaign action completed"
	result["cost"] = cost
	result["influence"] = influence
	result["saturation_before"] = saturation_before
	result["saturation_after"] = saturation_after
	result["risk_exposure"] = new_risk
	result["risk_class"] = risk_class
	result["effects"] = [effect.to_dictionary()]

	return result

static func _effect_id(
	action: S6CampaignAction,
	turn: int
) -> String:
	var raw := "%s|%s|%s|%s|%d" % [
		action.party_id,
		action.constituency_id,
		action.action_id,
		action.action_type,
		turn
	]

	return "effect-%s" % str(abs(raw.hash()))
