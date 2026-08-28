class_name S7ElectionReadyState
extends RefCounted

const SCHEMA_VERSION := 1

var schema_version: int = SCHEMA_VERSION

var campaign_id: String = ""

var final_week: int = 45
var final_phase: int = S7CampaignTimeline.Phase.COMPLETED

var final_political_state: Dictionary = {}
var final_campaign_state: Dictionary = {}
var final_economic_state: Dictionary = {}

var final_risk_state: Array = []
var final_constituency_states: Dictionary = {}

var action_history: Array = []
var resolution_history: Array = []

var model_versions: Dictionary = {}

func validate() -> Array[String]:
	var errors: Array[String] = []

	if schema_version != SCHEMA_VERSION:
		errors.append("unsupported election-ready schema version")

	if campaign_id.strip_edges().is_empty():
		errors.append("campaign_id must not be empty")

	if final_week < 1:
		errors.append("final_week must be >= 1")

	if final_political_state.is_empty():
		errors.append("final_political_state must not be empty")

	if final_campaign_state.is_empty():
		errors.append("final_campaign_state must not be empty")

	if final_economic_state.is_empty():
		errors.append("final_economic_state must not be empty")

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"campaign_id": campaign_id,
		"final_week": final_week,
		"final_phase": final_phase,
		"final_political_state": final_political_state.duplicate(true),
		"final_campaign_state": final_campaign_state.duplicate(true),
		"final_economic_state": final_economic_state.duplicate(true),
		"final_risk_state": final_risk_state.duplicate(true),
		"final_constituency_states": final_constituency_states.duplicate(true),
		"action_history": action_history.duplicate(true),
		"resolution_history": resolution_history.duplicate(true),
		"model_versions": model_versions.duplicate(true)
	}

static func from_dictionary(
	data: Dictionary
) -> S7ElectionReadyState:
	var result := S7ElectionReadyState.new()

	result.schema_version = int(
		data.get("schema_version", SCHEMA_VERSION)
	)

	result.campaign_id = String(
		data.get("campaign_id", "")
	)

	result.final_week = int(
		data.get("final_week", 45)
	)

	result.final_phase = int(
		data.get(
			"final_phase",
			S7CampaignTimeline.Phase.COMPLETED
		)
	)

	result.final_political_state = data.get(
		"final_political_state",
		{}
	).duplicate(true)

	result.final_campaign_state = data.get(
		"final_campaign_state",
		{}
	).duplicate(true)

	result.final_economic_state = data.get(
		"final_economic_state",
		{}
	).duplicate(true)

	result.final_risk_state = data.get(
		"final_risk_state",
		[]
	).duplicate(true)

	result.final_constituency_states = data.get(
		"final_constituency_states",
		{}
	).duplicate(true)

	result.action_history = data.get(
		"action_history",
		[]
	).duplicate(true)

	result.resolution_history = data.get(
		"resolution_history",
		[]
	).duplicate(true)

	result.model_versions = data.get(
		"model_versions",
		{}
	).duplicate(true)

	return result
