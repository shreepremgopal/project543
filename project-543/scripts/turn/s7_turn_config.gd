class_name S7TurnConfig
extends RefCounted

const SCHEMA_VERSION: int = 1
const DEFAULT_CAMPAIGN_WEEKS: int = 45
const DEFAULT_ACTIONS_PER_WEEK: int = 2

const TURN_MODEL_VERSION: String = "S7-R5-1.0"
const ECONOMY_MODEL_VERSION: String = "S6-1.0"
const POLITICAL_MODEL_VERSION: String = "S5-1.0"
const CONFIG_VERSION: String = "S7-1.0"

var schema_version: int = SCHEMA_VERSION
var campaign_weeks: int = DEFAULT_CAMPAIGN_WEEKS
var actions_per_week: int = DEFAULT_ACTIONS_PER_WEEK

var turn_model_version: String = TURN_MODEL_VERSION
var economy_model_version: String = ECONOMY_MODEL_VERSION
var political_model_version: String = POLITICAL_MODEL_VERSION
var config_version: String = CONFIG_VERSION


func _init(
	weeks: int = DEFAULT_CAMPAIGN_WEEKS,
	actions: int = DEFAULT_ACTIONS_PER_WEEK
) -> void:
	campaign_weeks = weeks
	actions_per_week = actions


func validate() -> Array:
	var errors: Array = []

	if campaign_weeks <= 0:
		errors.append("campaign_weeks must be greater than zero")

	if actions_per_week <= 0:
		errors.append("actions_per_week must be greater than zero")

	if turn_model_version.is_empty():
		errors.append("turn_model_version must not be empty")

	if economy_model_version.is_empty():
		errors.append("economy_model_version must not be empty")

	if political_model_version.is_empty():
		errors.append("political_model_version must not be empty")

	if config_version.is_empty():
		errors.append("config_version must not be empty")

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func to_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"campaign_weeks": campaign_weeks,
		"actions_per_week": actions_per_week,
		"turn_model_version": turn_model_version,
		"economy_model_version": economy_model_version,
		"political_model_version": political_model_version,
		"config_version": config_version
	}


static func from_dictionary(data: Dictionary):
	var result = S7TurnConfig.new(
		int(data.get("campaign_weeks", DEFAULT_CAMPAIGN_WEEKS)),
		int(data.get("actions_per_week", DEFAULT_ACTIONS_PER_WEEK))
	)

	result.schema_version = int(data.get("schema_version", SCHEMA_VERSION))
	result.turn_model_version = str(data.get("turn_model_version", TURN_MODEL_VERSION))
	result.economy_model_version = str(data.get("economy_model_version", ECONOMY_MODEL_VERSION))
	result.political_model_version = str(data.get("political_model_version", POLITICAL_MODEL_VERSION))
	result.config_version = str(data.get("config_version", CONFIG_VERSION))

	return result
