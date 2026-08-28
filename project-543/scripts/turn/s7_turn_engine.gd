class_name S7TurnEngine
extends RefCounted

const TurnConfigScript = preload("res://scripts/turn/s7_turn_config.gd")
const TimelineScript = preload("res://scripts/turn/s7_campaign_timeline.gd")
const WeekStateScript = preload("res://scripts/turn/s7_week_state.gd")
const ActionCommitmentScript = preload("res://scripts/turn/s7_action_commitment.gd")
const ActionQueueScript = preload("res://scripts/turn/s7_action_queue.gd")
const CampaignEventScript = preload("res://scripts/turn/s7_campaign_event.gd")
const EventLogScript = preload("res://scripts/turn/s7_event_log.gd")
const ResolutionPipelineScript = preload("res://scripts/turn/s7_resolution_pipeline.gd")
const ResolutionRecordScript = preload("res://scripts/turn/s7_resolution_record.gd")

const OK: String = "OK"
const INVALID_PHASE: String = "INVALID_PHASE"
const INVALID_WEEK: String = "INVALID_WEEK"
const ACTION_LIMIT_REACHED: String = "ACTION_LIMIT_REACHED"
const INVALID_ACTION: String = "INVALID_ACTION"
const INSUFFICIENT_FUNDS: String = "INSUFFICIENT_FUNDS"
const INVALID_TARGET: String = "INVALID_TARGET"
const DUPLICATE_ACTION: String = "DUPLICATE_ACTION"
const RESOLUTION_ALREADY_COMPLETE: String = "RESOLUTION_ALREADY_COMPLETE"
const STATE_CORRUPTED: String = "STATE_CORRUPTED"
const INVALID_CONFIGURATION: String = "INVALID_CONFIGURATION"

var config
var timeline
var week
var action_queue
var event_log
var pipeline

var campaign_state: Dictionary = {}
var resolution_history: Array = []
var action_history: Array = []

var initial_state: Dictionary = {}


func _init(
	config_value = null,
	campaign_id: String = "campaign_001"
) -> void:

	if config_value == null:
		config = TurnConfigScript.new()
	else:
		config = config_value

	timeline = TimelineScript.new(
		config.campaign_weeks,
		config.actions_per_week,
		campaign_id
	)

	week = WeekStateScript.new(
		1,
		config.actions_per_week
	)

	action_queue = ActionQueueScript.new()
	event_log = EventLogScript.new()
	pipeline = ResolutionPipelineScript.new()

	campaign_state = {
		"campaign_id": campaign_id,
		"week": 1,
		"money": 0,
		"effects": [],
		"risk": {
			"total": 0
		},
		"saturation": {
			"total": 0
		},
		"political": {
			"support": 0
		}
	}

	initial_state = campaign_state.duplicate(true)


func start() -> Dictionary:
	if config == null:
		return _failure(INVALID_CONFIGURATION)

	var errors: Array = config.validate()

	if not errors.is_empty():
		return _failure(
			INVALID_CONFIGURATION,
			errors
		)

	if timeline.phase == timeline.PRE_CAMPAIGN:
		timeline.start_campaign()

	return _success({
		"week": timeline.current_week,
		"phase": timeline.phase
	})


func begin_campaign() -> Dictionary:
	return start()


func current_week() -> int:
	return timeline.current_week


func actions_remaining() -> int:
	return week.actions_remaining


func actions_used() -> int:
	return week.actions_used


func commit_action(action) -> Dictionary:
	if timeline.phase != timeline.ACTIVE:
		return _failure(INVALID_PHASE)

	if timeline.current_week < 1:
		return _failure(INVALID_WEEK)

	if timeline.current_week > config.campaign_weeks:
		return _failure(INVALID_WEEK)

	if not week.can_commit_action():
		return _failure(ACTION_LIMIT_REACHED)

	if action == null:
		return _failure(INVALID_ACTION)

	if action.action_id.is_empty():
		return _failure(
			INVALID_ACTION,
			["action_id must not be empty"]
		)

	action.turn = timeline.current_week
	action.sequence = week.actions_used + 1

	var validation: Array = action.validate()

	if not validation.is_empty():
		return _failure(
			INVALID_ACTION,
			validation
		)

	var queued: Dictionary = action_queue.commit(action)

	if not bool(queued.get("ok", false)):
		return queued

	if not week.commit_action():
		return _failure(ACTION_LIMIT_REACHED)

	action_history.append(
		action.to_dictionary()
	)

	event_log.append(
		CampaignEventScript.new(
			CampaignEventScript.ACTION_COMMITTED,
			timeline.current_week,
			action.sequence,
			action.party_id,
			action.target,
			{
				"action_id": action.action_id
			},
			config.turn_model_version
		)
	)

	return _success({
		"action_id": action.action_id,
		"week": timeline.current_week,
		"sequence": action.sequence,
		"actions_remaining": week.actions_remaining
	})


func queue_action(action) -> Dictionary:
	return commit_action(action)


func resolve_week() -> Dictionary:
	if timeline.phase != timeline.ACTIVE:
		return _failure(INVALID_PHASE)

	if not timeline.can_resolve_week():
		return _failure(INVALID_WEEK)

	if week.resolved:
		return _failure(
			RESOLUTION_ALREADY_COMPLETE
		)

	var queued: Array = action_queue.get_week_actions(
		timeline.current_week
	)

	var state_before: Dictionary = (
		campaign_state.duplicate(true)
	)

	var pipeline_result: Dictionary = pipeline.execute(
		timeline.current_week,
		queued,
		state_before,
		config
	)

	if not bool(pipeline_result.get("ok", false)):
		return pipeline_result

	var record = pipeline_result.get("record", null)

	if record == null:
		return _failure(STATE_CORRUPTED)

	var candidate_state: Dictionary = (
		record.state_after.duplicate(true)
	)

	if not _validate_candidate_state(candidate_state):
		return _failure(STATE_CORRUPTED)

	# Commit only after the complete pipeline succeeds.
	campaign_state = candidate_state

	if not week.mark_resolved(record.resolution_id):
		# This should never happen, and because we haven't advanced
		# the timeline yet, the state remains structurally safe.
		return _failure(STATE_CORRUPTED)

	resolution_history.append(
		record.to_dictionary()
	)

	for action in queued:
		event_log.append(
			CampaignEventScript.new(
				CampaignEventScript.ACTION_RESOLVED,
				timeline.current_week,
				action.sequence,
				action.party_id,
				action.target,
				{
					"action_id": action.action_id,
					"resolution_id": record.resolution_id
				},
				config.turn_model_version
			)
		)

		if action.cost > 0:
			event_log.append(
				CampaignEventScript.new(
					CampaignEventScript.MONEY_SPENT,
					timeline.current_week,
					action.sequence,
					action.party_id,
					action.target,
					{
						"action_id": action.action_id,
						"amount": action.cost
					},
					config.turn_model_version
				)
			)

	for income_entry in record.income:
		event_log.append(
			CampaignEventScript.new(
				CampaignEventScript.INCOME_RECEIVED,
				timeline.current_week,
				0,
				"resolution",
				"campaign",
				income_entry,
				config.turn_model_version
			)
		)

	for effect in record.effects_added:
		event_log.append(
			CampaignEventScript.new(
				CampaignEventScript.EFFECT_CREATED,
				timeline.current_week,
				0,
				str(effect.get("source_action_id", "")),
				str(effect.get("type", "")),
				effect,
				config.turn_model_version
			)
		)

	for effect in record.effects_expired:
		event_log.append(
			CampaignEventScript.new(
				CampaignEventScript.EFFECT_EXPIRED,
				timeline.current_week,
				0,
				str(effect.get("source_action_id", "")),
				str(effect.get("type", "")),
				effect,
				config.turn_model_version
			)
		)

	for risk_change in record.risk_changes:
		event_log.append(
			CampaignEventScript.new(
				CampaignEventScript.RISK_CHANGED,
				timeline.current_week,
				0,
				"resolution",
				"campaign",
				risk_change,
				config.turn_model_version
			)
		)

	for saturation_change in record.saturation_changes:
		event_log.append(
			CampaignEventScript.new(
				CampaignEventScript.SATURATION_CHANGED,
				timeline.current_week,
				0,
				"resolution",
				"campaign",
				saturation_change,
				config.turn_model_version
			)
		)

	event_log.append(
		CampaignEventScript.new(
			CampaignEventScript.WEEK_RESOLVED,
			timeline.current_week,
			0,
			"turn_engine",
			"campaign",
			{
				"resolution_id": record.resolution_id,
				"action_count": queued.size()
			},
			config.turn_model_version
		)
	)

	action_queue.remove_week_actions(
		timeline.current_week
	)

	if timeline.current_week >= config.campaign_weeks:
		timeline.phase = timeline.COMPLETED
		campaign_state["week"] = config.campaign_weeks
	else:
		timeline.advance_week()

		week = WeekStateScript.new(
			timeline.current_week,
			config.actions_per_week
		)

		campaign_state["week"] = timeline.current_week

	return _success({
		"resolution": record.to_dictionary(),
		"week": timeline.current_week,
		"phase": timeline.phase
	})


func advance_week() -> Dictionary:
	return resolve_week()


func cancel_campaign() -> Dictionary:
	if timeline.phase == timeline.COMPLETED:
		return _failure(INVALID_PHASE)

	if timeline.phase == timeline.ELECTION_READY:
		return _failure(INVALID_PHASE)

	if not timeline.cancel_campaign():
		return _failure(INVALID_PHASE)

	return _success({
		"phase": timeline.phase
	})


func get_resolution_history() -> Array:
	return resolution_history.duplicate(true)


func get_action_history() -> Array:
	return action_history.duplicate(true)


func get_event_history() -> Array:
	return event_log.all_events()


func get_week_events() -> Array:
	return event_log.events_for_week(
		timeline.current_week
	)


func get_current_week_state():
	return week


func get_timeline():
	return timeline


func get_config():
	return config


func is_campaign_complete() -> bool:
	return timeline.is_complete()


func is_active() -> bool:
	return timeline.phase == timeline.ACTIVE


func get_state() -> Dictionary:
	return campaign_state.duplicate(true)


func set_state(state: Dictionary) -> Dictionary:
	if state == null:
		return _failure(STATE_CORRUPTED)

	var candidate: Dictionary = state.duplicate(true)

	if not _validate_candidate_state(candidate):
		return _failure(STATE_CORRUPTED)

	campaign_state = candidate

	return _success()


func to_dictionary() -> Dictionary:
	return {
		"config": config.to_dictionary(),
		"timeline": timeline.to_dictionary(),
		"week": week.to_dictionary(),
		"action_queue": action_queue.to_dictionary(),
		"event_log": event_log.to_dictionary(),
		"campaign_state": campaign_state.duplicate(true),
		"initial_state": initial_state.duplicate(true),
		"resolution_history": resolution_history.duplicate(true),
		"action_history": action_history.duplicate(true)
	}


func serialize() -> Dictionary:
	return to_dictionary()


func save_state() -> Dictionary:
	return to_dictionary()


static func from_dictionary(data: Dictionary):
	var config_data: Dictionary = data.get("config", {})

	var loaded_config = TurnConfigScript.from_dictionary(
		config_data
	)

	var timeline_data: Dictionary = data.get(
		"timeline",
		{}
	)

	var engine = S7TurnEngine.new(
		loaded_config,
		str(
			timeline_data.get(
				"campaign_id",
				"campaign_001"
			)
		)
	)

	engine.timeline = TimelineScript.from_dictionary(
		timeline_data
	)

	engine.week = WeekStateScript.from_dictionary(
		data.get("week", {})
	)

	engine.action_queue = ActionQueueScript.from_dictionary(
		data.get("action_queue", {})
	)

	engine.event_log = EventLogScript.from_dictionary(
		data.get("event_log", {})
	)

	engine.campaign_state = data.get(
		"campaign_state",
		{}
	).duplicate(true)

	engine.initial_state = data.get(
		"initial_state",
		engine.campaign_state
	).duplicate(true)

	engine.resolution_history = data.get(
		"resolution_history",
		[]
	).duplicate(true)

	engine.action_history = data.get(
		"action_history",
		[]
	).duplicate(true)

	return engine


static func deserialize(data: Dictionary):
	return from_dictionary(data)


static func load_state(data: Dictionary):
	return from_dictionary(data)


func create_election_handoff() -> Dictionary:
	if timeline.phase != timeline.COMPLETED:
		return _failure(INVALID_PHASE)

	return {
		"ok": true,
		"success": true,
		"code": OK,
		"election_ready": true,

		"final_political_state": campaign_state.get(
			"political",
			{}
		).duplicate(true),

		"final_campaign_effects": campaign_state.get(
			"effects",
			[]
		).duplicate(true),

		"final_economic_state": {
			"money": int(
				campaign_state.get("money", 0)
			)
		},

		"final_risk_state": campaign_state.get(
			"risk",
			{}
		).duplicate(true),

		"final_constituency_states": campaign_state.get(
			"constituencies",
			{}
		).duplicate(true),

		"action_history": action_history.duplicate(true),

		"resolution_history": resolution_history.duplicate(true)
	}


func get_election_handoff() -> Dictionary:
	return create_election_handoff()


func _validate_candidate_state(state: Dictionary) -> bool:
	if state == null:
		return false

	if not state.has("money"):
		return false

	if int(state.get("money", -1)) < 0:
		return false

	if not state.has("effects"):
		return false

	if not state.has("risk"):
		return false

	if not state.has("saturation"):
		return false

	return true


func _success(extra: Dictionary = {}) -> Dictionary:
	var result := {
		"ok": true,
		"success": true,
		"code": OK
	}

	for key in extra:
		result[key] = extra[key]

	return result


func _failure(
	code: String,
	errors: Array = []
) -> Dictionary:
	return {
		"ok": false,
		"success": false,
		"code": code,
		"errors": errors
	}
