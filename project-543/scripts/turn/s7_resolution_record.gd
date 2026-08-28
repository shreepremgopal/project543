class_name S7ResolutionRecord
extends RefCounted

var resolution_id: String = ""
var week: int = 1

var actions: Array = []
var transactions: Array = []
var effects_added: Array = []
var effects_expired: Array = []
var income: Array = []
var risk_changes: Array = []
var saturation_changes: Array = []

var state_before: Dictionary = {}
var state_after: Dictionary = {}

var stages_executed: Array = []

var turn_model_version: String = "S7-R5-1.0"
var economy_model_version: String = "S6-1.0"
var political_model_version: String = "S5-1.0"
var config_version: String = "S7-1.0"


func to_dictionary() -> Dictionary:
	return {
		"resolution_id": resolution_id,
		"week": week,
		"actions": actions.duplicate(true),
		"transactions": transactions.duplicate(true),
		"effects_added": effects_added.duplicate(true),
		"effects_expired": effects_expired.duplicate(true),
		"income": income.duplicate(true),
		"risk_changes": risk_changes.duplicate(true),
		"saturation_changes": saturation_changes.duplicate(true),
		"state_before": state_before.duplicate(true),
		"state_after": state_after.duplicate(true),
		"stages_executed": stages_executed.duplicate(true),
		"turn_model_version": turn_model_version,
		"economy_model_version": economy_model_version,
		"political_model_version": political_model_version,
		"config_version": config_version
	}


static func from_dictionary(data: Dictionary):
	var result = S7ResolutionRecord.new()

	result.resolution_id = str(data.get("resolution_id", ""))
	result.week = int(data.get("week", 1))

	result.actions = data.get("actions", []).duplicate(true)
	result.transactions = data.get("transactions", []).duplicate(true)
	result.effects_added = data.get("effects_added", []).duplicate(true)
	result.effects_expired = data.get("effects_expired", []).duplicate(true)
	result.income = data.get("income", []).duplicate(true)
	result.risk_changes = data.get("risk_changes", []).duplicate(true)
	result.saturation_changes = data.get("saturation_changes", []).duplicate(true)

	result.state_before = data.get("state_before", {}).duplicate(true)
	result.state_after = data.get("state_after", {}).duplicate(true)

	result.stages_executed = data.get("stages_executed", []).duplicate(true)

	result.turn_model_version = str(
		data.get("turn_model_version", "S7-R5-1.0")
	)

	result.economy_model_version = str(
		data.get("economy_model_version", "S6-1.0")
	)

	result.political_model_version = str(
		data.get("political_model_version", "S5-1.0")
	)

	result.config_version = str(
		data.get("config_version", "S7-1.0")
	)

	return result
