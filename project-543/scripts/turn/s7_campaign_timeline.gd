class_name S7CampaignTimeline
extends RefCounted

const PRE_CAMPAIGN: String = "PRE_CAMPAIGN"
const ACTIVE: String = "ACTIVE"
const ELECTION: String = "ELECTION"
const COMPLETED: String = "COMPLETED"
const CANCELLED: String = "CANCELLED"
const ELECTION_READY: String = "ELECTION_READY"

var campaign_id: String = "campaign_001"
var current_week: int = 1
var phase: String = PRE_CAMPAIGN
var campaign_weeks: int = 45
var actions_per_week: int = 2


func _init(
	weeks: int = 45,
	actions: int = 2,
	id: String = "campaign_001"
) -> void:
	campaign_weeks = weeks
	actions_per_week = actions
	campaign_id = id
	current_week = 1
	phase = PRE_CAMPAIGN


func start_campaign() -> bool:
	if phase != PRE_CAMPAIGN:
		return false

	current_week = 1
	phase = ACTIVE

	return true


func can_resolve_week() -> bool:
	return (
		phase == ACTIVE
		and current_week >= 1
		and current_week <= campaign_weeks
	)


func advance_week() -> bool:
	if phase != ACTIVE:
		return false

	if current_week >= campaign_weeks:
		phase = COMPLETED
		return true

	current_week += 1
	return true


func mark_election_ready() -> bool:
	if phase != COMPLETED:
		return false

	phase = ELECTION_READY
	return true


func cancel_campaign() -> bool:
	if phase == COMPLETED or phase == ELECTION_READY:
		return false

	phase = CANCELLED
	return true


func is_complete() -> bool:
	return phase == COMPLETED or phase == ELECTION_READY


func validate() -> Array:
	var errors: Array = []

	if campaign_weeks <= 0:
		errors.append("campaign_weeks must be > 0")

	if actions_per_week <= 0:
		errors.append("actions_per_week must be > 0")

	if current_week < 1:
		errors.append("current_week must be >= 1")

	if current_week > campaign_weeks:
		errors.append("current_week exceeds campaign_weeks")

	var valid_phases := [
		PRE_CAMPAIGN,
		ACTIVE,
		ELECTION,
		COMPLETED,
		CANCELLED,
		ELECTION_READY
	]

	if not valid_phases.has(phase):
		errors.append("invalid campaign phase")

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func to_dictionary() -> Dictionary:
	return {
		"campaign_id": campaign_id,
		"current_week": current_week,
		"phase": phase,
		"campaign_weeks": campaign_weeks,
		"actions_per_week": actions_per_week
	}


static func from_dictionary(data: Dictionary):
	var result = S7CampaignTimeline.new(
		int(data.get("campaign_weeks", 45)),
		int(data.get("actions_per_week", 2)),
		str(data.get("campaign_id", "campaign_001"))
	)

	result.current_week = int(data.get("current_week", 1))
	result.phase = str(data.get("phase", PRE_CAMPAIGN))

	return result
