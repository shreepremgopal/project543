class_name S7CampaignEvent
extends RefCounted

const ACTION_COMMITTED: String = "ACTION_COMMITTED"
const ACTION_RESOLVED: String = "ACTION_RESOLVED"
const MONEY_SPENT: String = "MONEY_SPENT"
const INCOME_RECEIVED: String = "INCOME_RECEIVED"
const EFFECT_CREATED: String = "EFFECT_CREATED"
const EFFECT_EXPIRED: String = "EFFECT_EXPIRED"
const RISK_CHANGED: String = "RISK_CHANGED"
const SATURATION_CHANGED: String = "SATURATION_CHANGED"
const WEEK_RESOLVED: String = "WEEK_RESOLVED"

var event_type: String = ""
var week: int = 1
var sequence: int = 1
var source: String = ""
var target: String = ""
var payload: Dictionary = {}
var model_version: String = "S7-R5-1.0"


func _init(
	type_value: String = "",
	week_value: int = 1,
	sequence_value: int = 1,
	source_value: String = "",
	target_value: String = "",
	payload_value: Dictionary = {},
	version_value: String = "S7-R5-1.0"
) -> void:
	event_type = type_value
	week = week_value
	sequence = sequence_value
	source = source_value
	target = target_value
	payload = payload_value.duplicate(true)
	model_version = version_value


func validate() -> Array:
	var errors: Array = []

	if event_type.strip_edges().is_empty():
		errors.append("event_type must not be empty")

	if week < 1:
		errors.append("week must be >= 1")

	if sequence < 0:
		errors.append("sequence must be >= 0")

	if model_version.strip_edges().is_empty():
		errors.append("model_version must not be empty")

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func to_dictionary() -> Dictionary:
	return {
		"event_type": event_type,
		"week": week,
		"sequence": sequence,
		"source": source,
		"target": target,
		"payload": payload.duplicate(true),
		"model_version": model_version
	}


static func from_dictionary(data: Dictionary):
	return S7CampaignEvent.new(
		str(data.get("event_type", "")),
		int(data.get("week", 1)),
		int(data.get("sequence", 0)),
		str(data.get("source", "")),
		str(data.get("target", "")),
		data.get("payload", {}),
		str(data.get("model_version", "S7-R5-1.0"))
	)
