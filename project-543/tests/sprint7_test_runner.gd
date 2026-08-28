extends RefCounted

const S7TurnEngineScript = preload("res://scripts/turn/s7_turn_engine.gd")
const S7TurnConfigScript = preload("res://scripts/turn/s7_turn_config.gd")
const S7WeekStateScript = preload("res://scripts/turn/s7_week_state.gd")
const S7ActionCommitmentScript = preload("res://scripts/turn/s7_action_commitment.gd")
const S7CampaignEventScript = preload("res://scripts/turn/s7_campaign_event.gd")
const S7CampaignTimelineScript = preload("res://scripts/turn/s7_campaign_timeline.gd")
const S7ResolutionPipelineScript = preload("res://scripts/turn/s7_resolution_pipeline.gd")

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	run_all()


func run_all() -> void:
	passed = 0
	failed = 0

	print("")
	print("==============================================")
	print(" PROJECT543 — SPRINT 7 ACCEPTANCE TEST SUITE")
	print("==============================================")
	print("")

	_test_config()
	_test_timeline()
	_test_week_state()
	_test_action_validation()
	_test_two_action_limit()
	_test_action_ordering()
	_test_invalid_phase()
	_test_resolution_pipeline()
	_test_atomic_insufficient_funds()
	_test_effect_lifecycle()
	_test_risk_and_saturation()
	_test_income()
	_test_determinism()
	_test_serialization()
	_test_resume_determinism()
	_test_event_history()
	_test_45_week_boundary()
	_test_election_handoff()
	_test_fault_injection()

	print("")
	print("==============================================")
	print(" SPRINT 7 RESULT")
	print("==============================================")
	print("PASSED: %d" % passed)
	print("FAILED: %d" % failed)
	print("TOTAL : %d" % (passed + failed))
	print("==============================================")

	if failed == 0:
		print("SPRINT 7: PASS")
	else:
		print("SPRINT 7: FAIL")

	print("")


func _test_config() -> void:
	var config = S7TurnConfigScript.new()

	_assert(
		config.campaign_weeks == 45,
		"default campaign duration is 45 weeks"
	)

	_assert(
		config.actions_per_week == 2,
		"default actions per week is 2"
	)

	_assert(
		config.is_valid(),
		"default configuration validates"
	)


func _test_timeline() -> void:
	var timeline = S7CampaignTimelineScript.new()

	_assert(
		timeline.phase == timeline.PRE_CAMPAIGN,
		"timeline starts PRE_CAMPAIGN"
	)

	_assert(
		timeline.current_week == 1,
		"timeline starts at week 1"
	)

	_assert(
		timeline.start_campaign(),
		"campaign starts"
	)

	_assert(
		timeline.phase == timeline.ACTIVE,
		"timeline becomes ACTIVE"
	)

	_assert(
		timeline.advance_week(),
		"timeline advances"
	)

	_assert(
		timeline.current_week == 2,
		"timeline advances to week 2"
	)


func _test_week_state() -> void:
	var week = S7WeekStateScript.new(1, 2)

	_assert(
		week.actions_remaining == 2,
		"week starts with two actions"
	)

	_assert(
		week.commit_action(),
		"first action commits"
	)

	_assert(
		week.actions_remaining == 1,
		"one action remains"
	)

	_assert(
		week.commit_action(),
		"second action commits"
	)

	_assert(
		week.actions_remaining == 0,
		"zero actions remain"
	)

	_assert(
		not week.commit_action(),
		"third action rejected"
	)


func _test_action_validation() -> void:
	var invalid = S7ActionCommitmentScript.new()

	_assert(
		not invalid.is_valid(),
		"empty action rejected"
	)

	var valid = _action(
		"action_001",
		"party_a",
		"constituency_1",
		0
	)

	_assert(
		valid.is_valid(),
		"valid action accepted"
	)


func _test_two_action_limit() -> void:
	var engine = _new_engine()
	engine.start()

	var first = engine.commit_action(
		_action(
			"a1",
			"party",
			"target",
			0
		)
	)

	var second = engine.commit_action(
		_action(
			"a2",
			"party",
			"target",
			0
		)
	)

	var third = engine.commit_action(
		_action(
			"a3",
			"party",
			"target",
			0
		)
	)

	_assert(
		first.ok,
		"first weekly action accepted"
	)

	_assert(
		second.ok,
		"second weekly action accepted"
	)

	_assert(
		not third.ok,
		"third weekly action rejected"
	)

	_assert(
		third.code == "ACTION_LIMIT_REACHED",
		"third action has deterministic failure code"
	)


func _test_action_ordering() -> void:
	var engine = _new_engine()
	engine.start()

	engine.commit_action(
		_action(
			"first",
			"party",
			"target",
			0
		)
	)

	engine.commit_action(
		_action(
			"second",
			"party",
			"target",
			0
		)
	)

	var result = engine.resolve_week()

	_assert(
		result.ok,
		"ordered actions resolve"
	)

	var actions = result.resolution.actions

	_assert(
		actions.size() == 2,
		"both actions are recorded"
	)

	if actions.size() == 2:
		_assert(
			actions[0]["sequence"] == 1,
			"first action sequence preserved"
		)

		_assert(
			actions[1]["sequence"] == 2,
			"second action sequence preserved"
		)


func _test_invalid_phase() -> void:
	var engine = _new_engine()

	var action = _action(
		"before_start",
		"party",
		"target",
		0
	)

	var result = engine.commit_action(action)

	_assert(
		not result.ok,
		"action before campaign start rejected"
	)

	_assert(
		result.code == "INVALID_PHASE",
		"invalid phase has correct code"
	)


func _test_resolution_pipeline() -> void:
	var pipeline = S7ResolutionPipelineScript.new()

	var stages = pipeline.get_stages()

	_assert(
		stages.size() == 9,
		"resolution pipeline contains nine stages"
	)

	if stages.size() == 9:
		_assert(
			stages[0] == pipeline.ACTION_VALIDATION,
			"validation is first"
		)

		_assert(
			stages[1] == pipeline.ECONOMIC_COMMIT,
			"economic commit is second"
		)

		_assert(
			stages[2] == pipeline.CAMPAIGN_RESOLUTION,
			"campaign resolution is third"
		)

		_assert(
			stages[3] == pipeline.POLITICAL_EFFECT_APPLICATION,
			"political effects are fourth"
		)

		_assert(
			stages[4] == pipeline.RISK_UPDATE,
			"risk update is fifth"
		)

		_assert(
			stages[5] == pipeline.SATURATION_UPDATE,
			"saturation update is sixth"
		)

		_assert(
			stages[6] == pipeline.INCOME_RESOLUTION,
			"income is seventh"
		)

		_assert(
			stages[7] == pipeline.EXPIRY,
			"expiry is eighth"
		)

		_assert(
			stages[8] == pipeline.WEEK_FINALIZATION,
			"finalization is ninth"
		)


func _test_atomic_insufficient_funds() -> void:
	var engine = _new_engine()

	engine.start()

	engine.set_state({
		"campaign_id": "atomic",
		"week": 1,
		"money": 10,
		"effects": [],
		"risk": {"total": 0},
		"saturation": {"total": 0},
		"political": {"support": 0}
	})

	engine.commit_action(
		_action(
			"expensive",
			"party",
			"target",
			100
		)
	)

	var before = engine.get_state()

	var result = engine.resolve_week()

	var after = engine.get_state()

	_assert(
		not result.ok,
		"insufficient funds rejected"
	)

	_assert(
		result.code == "INSUFFICIENT_FUNDS",
		"insufficient funds code correct"
	)

	_assert(
		before == after,
		"failed resolution leaves state unchanged"
	)


func _test_effect_lifecycle() -> void:
	var engine = _new_engine()

	engine.start()

	var action = _action(
		"effect_action",
		"party",
		"target",
		0
	)

	action.parameters["effect"] = {
		"type": "temporary_support"
	}

	action.parameters["duration"] = 1

	engine.commit_action(action)

	var result = engine.resolve_week()

	_assert(
		result.ok,
		"effect action resolves"
	)

	_assert(
		result.resolution.effects_added.size() == 1,
		"effect is created"
	)

	var state = engine.get_state()

	_assert(
		state.effects.size() == 1,
		"temporary effect persists for its active week"
	)

	var action2 = _action(
		"noop",
		"party",
		"target",
		0
	)

	engine.commit_action(action2)

	var result2 = engine.resolve_week()

	_assert(
		result2.ok,
		"following week resolves"
	)

	_assert(
		result2.resolution.effects_expired.size() == 1,
		"temporary effect expires"
	)

	_assert(
		engine.get_state().effects.size() == 0,
		"expired effect removed from state"
	)


func _test_risk_and_saturation() -> void:
	var engine = _new_engine()

	engine.start()

	var action = _action(
		"risk_sat",
		"party",
		"target",
		0
	)

	action.parameters["risk_delta"] = 3
	action.parameters["saturation_delta"] = 4

	engine.commit_action(action)

	var result = engine.resolve_week()

	_assert(
		result.ok,
		"risk/saturation action resolves"
	)

	var state = engine.get_state()

	_assert(
		state.risk.total == 3,
		"risk delta applied"
	)

	_assert(
		state.saturation.total == 4,
		"saturation delta applied"
	)


func _test_income() -> void:
	var engine = _new_engine()

	engine.start()

	engine.set_state({
		"campaign_id": "income",
		"week": 1,
		"money": 100,
		"effects": [],
		"risk": {"total": 0},
		"saturation": {"total": 0},
		"political": {"support": 0}
	})

	var action = _action(
		"income",
		"party",
		"target",
		20
	)

	action.parameters["income"] = 50

	engine.commit_action(action)

	var result = engine.resolve_week()

	_assert(
		result.ok,
		"income action resolves"
	)

	_assert(
		engine.get_state().money == 130,
		"cost and income are both reflected"
	)

	_assert(
		result.resolution.transactions.size() == 1,
		"cost transaction recorded"
	)

	_assert(
		result.resolution.income.size() == 1,
		"income recorded"
	)


func _test_determinism() -> void:
	var a = _new_engine()
	var b = _new_engine()

	a.start()
	b.start()

	var action_a = _action(
		"deterministic",
		"party",
		"target",
		10
	)

	var action_b = _action(
		"deterministic",
		"party",
		"target",
		10
	)

	action_a.parameters["risk_delta"] = 2
	action_b.parameters["risk_delta"] = 2

	a.commit_action(action_a)
	b.commit_action(action_b)

	var result_a = a.resolve_week()
	var result_b = b.resolve_week()

	_assert(
		result_a == result_b,
		"identical inputs produce identical results"
	)

	_assert(
		a.get_state() == b.get_state(),
		"identical inputs produce identical states"
	)

	_assert(
		a.get_event_history().map(func(x): return x.to_dictionary())
		==
		b.get_event_history().map(func(x): return x.to_dictionary()),
		"identical inputs produce identical event history"
	)


func _test_serialization() -> void:
	var engine = _new_engine()

	engine.start()

	engine.commit_action(
		_action(
			"save_test",
			"party",
			"target",
			0
		)
	)

	var saved = engine.serialize()

	var restored = S7TurnEngineScript.from_dictionary(
		saved
	)

	_assert(
		restored.get_state() == engine.get_state(),
		"serialized state restores"
	)

	_assert(
		restored.get_timeline().to_dictionary()
		==
		engine.get_timeline().to_dictionary(),
		"timeline restores"
	)

	_assert(
		restored.get_event_history().size()
		==
		engine.get_event_history().size(),
		"event history restores"
	)


func _test_resume_determinism() -> void:
	var continuous = _new_engine()
	var resumed = _new_engine()

	continuous.start()
	resumed.start()

	for i in range(1, 11):
		var action_id := "resume_%02d" % i

		var action_a = _action(
			action_id,
			"party",
			"target",
			0
		)

		continuous.commit_action(action_a)
		continuous.resolve_week()

		if i <= 5:
			var action_b = _action(
				action_id,
				"party",
				"target",
				0
			)

			resumed.commit_action(action_b)
			resumed.resolve_week()

			if i == 5:
				var saved = resumed.serialize()

				resumed = S7TurnEngineScript.from_dictionary(
					saved
				)

		else:
			var action_c = _action(
				action_id,
				"party",
				"target",
				0
			)

			resumed.commit_action(action_c)
			resumed.resolve_week()

	_assert(
		continuous.current_week() == resumed.current_week(),
		"resume reaches same week"
	)

	_assert(
		continuous.get_state() == resumed.get_state(),
		"resume produces same final state"
	)

	_assert(
		continuous.get_event_history().map(
			func(x): return x.to_dictionary()
		)
		==
		resumed.get_event_history().map(
			func(x): return x.to_dictionary()
		),
		"resume produces same event history"
	)


func _test_event_history() -> void:
	var engine = _new_engine()

	engine.start()

	engine.commit_action(
		_action(
			"event_test",
			"party",
			"target",
			10
		)
	)

	var result = engine.resolve_week()

	_assert(
		result.ok,
		"event test resolves"
	)

	var events = engine.get_event_history()

	_assert(
		events.size() >= 3,
		"event log records campaign activity"
	)

	var found_commit := false
	var found_resolution := false
	var found_spend := false
	var found_week := false

	for event in events:
		if event.event_type == S7CampaignEventScript.ACTION_COMMITTED:
			found_commit = true

		if event.event_type == S7CampaignEventScript.ACTION_RESOLVED:
			found_resolution = true

		if event.event_type == S7CampaignEventScript.MONEY_SPENT:
			found_spend = true

		if event.event_type == S7CampaignEventScript.WEEK_RESOLVED:
			found_week = true

	_assert(found_commit, "ACTION_COMMITTED event exists")
	_assert(found_resolution, "ACTION_RESOLVED event exists")
	_assert(found_spend, "MONEY_SPENT event exists")
	_assert(found_week, "WEEK_RESOLVED event exists")


func _test_45_week_boundary() -> void:
	var engine = _new_engine()

	engine.start()

	for week_index in range(1, 46):
		var action = _action(
			"week_%02d" % week_index,
			"party",
			"target",
			0
		)

		var commit_result = engine.commit_action(action)

		_assert(
			commit_result.ok,
			"week %d action commits" % week_index
		)

		var resolve_result = engine.resolve_week()

		_assert(
			resolve_result.ok,
			"week %d resolves" % week_index
		)

	_assert(
		engine.get_timeline().phase
		==
		S7CampaignTimelineScript.COMPLETED,
		"campaign completes after week 45"
	)

	_assert(
		engine.get_timeline().current_week == 45,
		"final authoritative week is 45"
	)

	var extra = engine.commit_action(
		_action(
			"after_campaign",
			"party",
			"target",
			0
		)
	)

	_assert(
		not extra.ok,
		"actions after campaign completion rejected"
	)


func _test_election_handoff() -> void:
	var engine = _new_engine()

	engine.start()

	for week_index in range(1, 46):
		engine.commit_action(
			_action(
				"handoff_%02d" % week_index,
				"party",
				"target",
				0
			)
		)

		engine.resolve_week()

	var handoff = engine.create_election_handoff()

	_assert(
		handoff.ok,
		"election handoff emitted"
	)

	_assert(
		handoff.election_ready,
		"handoff is election-ready"
	)

	_assert(
		handoff.has("final_political_state"),
		"handoff contains political state"
	)

	_assert(
		handoff.has("final_campaign_effects"),
		"handoff contains campaign effects"
	)

	_assert(
		handoff.has("final_economic_state"),
		"handoff contains economic state"
	)

	_assert(
		handoff.has("final_risk_state"),
		"handoff contains risk state"
	)

	_assert(
		handoff.has("final_constituency_states"),
		"handoff contains constituency states"
	)

	_assert(
		handoff.has("action_history"),
		"handoff contains action history"
	)

	_assert(
		handoff.has("resolution_history"),
		"handoff contains resolution history"
	)

	_assert(
		not handoff.has("winner"),
		"R5 does not calculate election winner"
	)

	_assert(
		not handoff.has("seats"),
		"R5 does not calculate seat allocation"
	)


func _test_fault_injection() -> void:
	var engine = _new_engine()

	var result = engine.commit_action(null)

	_assert(
		not result.ok,
		"null action rejected cleanly"
	)

	var malformed_event = S7CampaignEventScript.new(
		"",
		0,
		-1
	)

	_assert(
		not malformed_event.is_valid(),
		"malformed event rejected"
	)

	var invalid_config = S7TurnConfigScript.new(
		0,
		0
	)

	_assert(
		not invalid_config.is_valid(),
		"invalid configuration rejected"
	)

	var invalid_week = S7WeekStateScript.new(
		0,
		2
	)

	_assert(
		not invalid_week.is_valid(),
		"invalid week rejected"
	)


func _new_engine():
	return S7TurnEngineScript.new(
		S7TurnConfigScript.new(),
		"test_campaign"
	)


func _action(
	id: String,
	party: String,
	target: String,
	cost: int
):
	return S7ActionCommitmentScript.new(
		id,
		party,
		target,
		{},
		1,
		1,
		cost
	)


func _assert(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("[PASS] " + description)
	else:
		failed += 1
		push_error("[FAIL] " + description)
