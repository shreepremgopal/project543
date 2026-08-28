class_name S7ResolutionPipeline
extends RefCounted

const ACTION_VALIDATION: String = "ACTION_VALIDATION"
const ECONOMIC_COMMIT: String = "ECONOMIC_COMMIT"
const CAMPAIGN_RESOLUTION: String = "CAMPAIGN_RESOLUTION"
const POLITICAL_EFFECT_APPLICATION: String = "POLITICAL_EFFECT_APPLICATION"
const RISK_UPDATE: String = "RISK_UPDATE"
const SATURATION_UPDATE: String = "SATURATION_UPDATE"
const INCOME_RESOLUTION: String = "INCOME_RESOLUTION"
const EXPIRY: String = "EXPIRY"
const WEEK_FINALIZATION: String = "WEEK_FINALIZATION"

const STAGES: Array = [ACTION_VALIDATION, ECONOMIC_COMMIT, CAMPAIGN_RESOLUTION, POLITICAL_EFFECT_APPLICATION, RISK_UPDATE, SATURATION_UPDATE, INCOME_RESOLUTION, EXPIRY, WEEK_FINALIZATION]

func get_stages() -> Array:
	return STAGES.duplicate()

func execute(week: int, actions: Array, state_before: Dictionary, config) -> Dictionary:
	var record = S7ResolutionRecord.new()
	record.resolution_id = _make_resolution_id(str(state_before.get("campaign_id", "campaign_001")), week, str(config.config_version))
	record.week = week
	record.state_before = state_before.duplicate(true)
	record.turn_model_version = config.turn_model_version
	record.economy_model_version = config.economy_model_version
	record.political_model_version = config.political_model_version
	record.config_version = config.config_version

	var validation := _validate_actions(actions, week)
	if not validation["ok"]:
		return validation
	record.stages_executed.append(ACTION_VALIDATION)

	var working_state: Dictionary = state_before.duplicate(true)
	if not working_state.has("money"):
		working_state["money"] = 0
	if not working_state.has("effects"):
		working_state["effects"] = []
	if not working_state.has("risk"):
		working_state["risk"] = {}
	if not working_state.has("saturation"):
		working_state["saturation"] = {}

	var money: int = int(working_state.get("money", 0))
	var total_cost := 0
	for action in actions:
		total_cost += int(action.cost)
	if money < total_cost:
		return {"ok": false, "code": "INSUFFICIENT_FUNDS", "errors": ["required=%d available=%d" % [total_cost, money]]}
	money -= total_cost
	working_state["money"] = money
	for action in actions:
		if action.cost > 0:
			record.transactions.append({"action_id": action.action_id, "type": "COST", "amount": action.cost})
	record.stages_executed.append(ECONOMIC_COMMIT)

	for action in actions:
		record.actions.append(action.to_dictionary())
		var effect = _build_effect(action, week)
		if effect != null:
			working_state["effects"].append(effect)
			record.effects_added.append(effect)
	record.stages_executed.append(CAMPAIGN_RESOLUTION)

	for action in actions:
		var political_delta := int(action.parameters.get("political_delta", 0))
		if political_delta != 0:
			var political_state: Dictionary = working_state.get("political", {}).duplicate(true)
			political_state["support"] = int(political_state.get("support", 0)) + political_delta
			working_state["political"] = political_state
	record.stages_executed.append(POLITICAL_EFFECT_APPLICATION)

	var risk_delta := 0
	for action in actions:
		risk_delta += int(action.parameters.get("risk_delta", 0))
	if risk_delta != 0:
		var risk_state: Dictionary = working_state.get("risk", {}).duplicate(true)
		var current_risk := int(risk_state.get("total", 0))
		risk_state["total"] = current_risk + risk_delta
		working_state["risk"] = risk_state
		record.risk_changes.append({"week": week, "delta": risk_delta, "total": current_risk + risk_delta})
	record.stages_executed.append(RISK_UPDATE)

	var saturation_delta := 0
	for action in actions:
		saturation_delta += int(action.parameters.get("saturation_delta", 0))
	if saturation_delta != 0:
		var saturation_state: Dictionary = working_state.get("saturation", {}).duplicate(true)
		var current_saturation := int(saturation_state.get("total", 0))
		saturation_state["total"] = current_saturation + saturation_delta
		working_state["saturation"] = saturation_state
		record.saturation_changes.append({"week": week, "delta": saturation_delta, "total": current_saturation + saturation_delta})
	record.stages_executed.append(SATURATION_UPDATE)

	var income_amount := 0
	for action in actions:
		income_amount += int(action.parameters.get("income", 0))
	if income_amount != 0:
		working_state["money"] = int(working_state.get("money", 0)) + income_amount
		record.income.append({"week": week, "amount": income_amount})
	record.stages_executed.append(INCOME_RESOLUTION)

	var retained_effects: Array = []
	for effect in working_state.get("effects", []):
		var expiry_week := int(effect.get("expiry_week", -1))
		if expiry_week >= 0 and expiry_week <= week:
			record.effects_expired.append(effect)
		else:
			retained_effects.append(effect)
	working_state["effects"] = retained_effects
	record.stages_executed.append(EXPIRY)

	working_state["week"] = week + 1
	record.state_after = working_state.duplicate(true)
	record.stages_executed.append(WEEK_FINALIZATION)
	return {"ok": true, "code": "OK", "record": record}

func _validate_actions(actions: Array, week: int) -> Dictionary:
	for action in actions:
		if action == null:
			return {"ok": false, "code": "INVALID_ACTION", "errors": ["null action"]}
		var errors: Array = action.validate()
		if not errors.is_empty():
			return {"ok": false, "code": "INVALID_ACTION", "errors": errors}
		if int(action.turn) != week:
			return {"ok": false, "code": "INVALID_WEEK", "errors": ["action %s belongs to week %d, expected %d" % [action.action_id, action.turn, week]]}
	return {"ok": true, "code": "OK"}

func _build_effect(action, week: int):
	var effect_data = action.parameters.get("effect", null)
	if effect_data == null:
		return null
	var effect: Dictionary = effect_data.duplicate(true) if effect_data is Dictionary else {"type": str(effect_data)}
	effect["source_action_id"] = action.action_id
	effect["created_week"] = week
	var duration := int(action.parameters.get("duration", 0))
	effect["expiry_week"] = week + duration if duration > 0 else -1
	return effect

func _make_resolution_id(campaign_id: String, week: int, config_version: String) -> String:
	return "%s-W%02d-%s" % [campaign_id, week, config_version]
