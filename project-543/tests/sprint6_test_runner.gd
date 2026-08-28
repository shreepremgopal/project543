extends SceneTree

const EPSILON: float = 0.0001

var failures: Array[String] = []


func _initialize() -> void:
	_test_config()
	_test_money_ledger()
	_test_business()
	_test_income()
	_test_fundraising()
	_test_risk()
	_test_saturation()
	_test_temporary_effect()
	_test_permanent_effect()
	_test_campaign_action()
	_test_campaign_determinism()
	_test_campaign_isolation()
	_test_serialization()
	_test_anti_exploits()

	if failures.is_empty():
		print("SPRINT 6 PASS: all economy and campaign tests passed.")
		quit(0)
		return

	for failure: String in failures:
		print("SPRINT 6 FAILURE: " + failure)

	quit(1)


func _test_config() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()

	_check(
		config.is_valid(),
		"default economy config invalid"
	)

	_check(
		S6EconomyConfig.MODEL_VERSION == "economy-v0.1",
		"unexpected economy model version"
	)


func _test_money_ledger() -> void:
	var ledger: S6MoneyLedger = S6MoneyLedger.new(10000)

	_check(
		ledger.balance == 10000,
		"initial money incorrect"
	)

	_check(
		ledger.receive(
			"test-income",
			5000,
			1,
			"test income",
			S6MoneyTransaction.TYPES.INCOME
		),
		"income transaction rejected"
	)

	_check(
		ledger.balance == 15000,
		"income balance incorrect"
	)

	_check(
		ledger.spend(
			"test-spend",
			3000,
			1,
			"test spending"
		),
		"spending transaction rejected"
	)

	_check(
		ledger.balance == 12000,
		"spending balance incorrect"
	)

	_check(
		not ledger.spend(
			"too-large",
			20000,
			1,
			"should fail"
		),
		"overspending was accepted"
	)

	_check(
		ledger.balance == 12000,
		"failed spend changed balance"
	)

	_check(
		ledger.is_valid(),
		"ledger conservation failed"
	)


func _test_business() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()

	var business: S6Business = S6Business.new(
		"business-a",
		"constituency-a",
		100000,
		10000,
		0.0,
		0.0,
		0.0
	)

	_check(
		business.is_valid(),
		"valid business rejected"
	)

	_check(
		business.calculate_income(config) == 10000,
		"business income incorrect"
	)

	business.status = S6Business.STATUS_INACTIVE

	_check(
		business.calculate_income(config) == 0,
		"inactive business generated income"
	)

	var invalid: S6Business = S6Business.new(
		"",
		"",
		-1,
		-1,
		2.0,
		0.0,
		0.0
	)

	_check(
		not invalid.is_valid(),
		"invalid business accepted"
	)


func _test_income() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()
	var economy: S6EconomyState = S6EconomyState.new(
		"party-a",
		0
	)

	var business: S6Business = S6Business.new(
		"business-a",
		"c1",
		100000,
		10000,
		0.0,
		0.0,
		0.0
	)

	_check(
		economy.add_business(business),
		"could not add business"
	)

	var result: Dictionary = economy.collect_income(
		1,
		config
	)

	_check(
		bool(result["success"]),
		"income collection failed"
	)

	_check(
		economy.ledger.balance == 10000,
		"income was not recorded"
	)


func _test_fundraising() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()
	var economy: S6EconomyState = S6EconomyState.new(
		"party-a",
		10000
	)

	var action: S6FundraisingAction = S6FundraisingAction.new(
		"fund-1",
		"party-a",
		10000,
		1000,
		0.5,
		1
	)

	var result: S6FundraisingResult = economy.fundraise(
		action,
		1,
		config
	)

	_check(
		result.success,
		"fundraising failed"
	)

	_check(
		result.net_amount == 7000,
		"fundraising net amount incorrect"
	)

	_check(
		economy.ledger.balance == 17000,
		"fundraising balance incorrect"
	)

	var repeat: S6FundraisingResult = economy.fundraise(
		action,
		1,
		config
	)

	_check(
		not repeat.success,
		"fundraising cooldown failed"
	)

	var next_turn: S6FundraisingResult = economy.fundraise(
		action,
		2,
		config
	)

	_check(
		next_turn.success,
		"fundraising did not resume after cooldown"
	)


func _test_risk() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()

	var low: S6RiskProfile = S6RiskProfile.new(
		0.1,
		0.1,
		0.0
	)

	var high: S6RiskProfile = S6RiskProfile.new(
		0.9,
		0.9,
		0.8
	)

	_check(
		low.is_valid(),
		"low risk profile invalid"
	)

	_check(
		high.is_valid(),
		"high risk profile invalid"
	)

	_check(
		low.calculate_exposure() < high.calculate_exposure(),
		"risk ordering failed"
	)

	_check(
		low.classify(config) == S6RiskProfile.LOW,
		"low risk classification failed"
	)

	_check(
		high.classify(config) == S6RiskProfile.HIGH,
		"high risk classification failed"
	)


func _test_saturation() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()
	var saturation: S6SaturationState = S6SaturationState.new()

	var first: float = saturation.calculate_multiplier(
		"party",
		"c1",
		"rally",
		config
	)

	_check(
		abs(first - 1.0) <= EPSILON,
		"initial saturation multiplier incorrect"
	)

	_check(
		saturation.apply(
			"party",
			"c1",
			"rally",
			1.0
		),
		"could not apply saturation"
	)

	var second: float = saturation.calculate_multiplier(
		"party",
		"c1",
		"rally",
		config
	)

	_check(
		second < first,
		"saturation did not reduce effectiveness"
	)

	var other_constituency: float = saturation.calculate_multiplier(
		"party",
		"c2",
		"rally",
		config
	)

	_check(
		abs(other_constituency - 1.0) <= EPSILON,
		"saturation leaked between constituencies"
	)

	var other_action: float = saturation.calculate_multiplier(
		"party",
		"c1",
		"interview",
		config
	)

	_check(
		abs(other_action - 1.0) <= EPSILON,
		"saturation leaked between action families"
	)


func _test_temporary_effect() -> void:
	var effect: S6CampaignEffect = S6CampaignEffect.new(
		"e1",
		"a1",
		"party",
		"c1",
		"rally",
		0.1,
		5,
		2,
		false
	)

	_check(
		effect.is_valid(),
		"temporary effect invalid"
	)

	_check(
		not effect.is_active(4),
		"effect active before start"
	)

	_check(
		effect.is_active(5),
		"effect not active at start"
	)

	_check(
		effect.is_active(6),
		"effect expired too early"
	)

	_check(
		not effect.is_active(7),
		"effect did not expire"
	)


func _test_permanent_effect() -> void:
	var effect: S6CampaignEffect = S6CampaignEffect.new(
		"e2",
		"a2",
		"party",
		"c1",
		"manifesto",
		0.1,
		5,
		0,
		true
	)

	_check(
		effect.is_valid(),
		"permanent effect invalid"
	)

	_check(
		effect.is_active(1000),
		"permanent effect expired"
	)

	_check(
		effect.remaining_duration(1000) == -1,
		"permanent effect duration incorrect"
	)


func _test_campaign_action() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()

	var action: S6CampaignAction = S6CampaignAction.new(
		"rally-1",
		S6CampaignAction.RALLY,
		"party",
		"c1",
		5000,
		1.0,
		0.3,
		2,
		1.0
	)

	_check(
		action.is_valid(config),
		"valid campaign action rejected"
	)

	var invalid: S6CampaignAction = S6CampaignAction.new(
		"",
		"invalid",
		"",
		"",
		-1,
		0.0,
		2.0,
		-1,
		0.0
	)

	_check(
		not invalid.is_valid(config),
		"invalid campaign action accepted"
	)


func _test_campaign_determinism() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()

	var action: S6CampaignAction = S6CampaignAction.new(
		"rally-1",
		S6CampaignAction.RALLY,
		"party",
		"c1",
		5000,
		1.0,
		0.3,
		2,
		1.0
	)

	var economy_a: S6EconomyState = S6EconomyState.new(
		"party",
		20000
	)

	var campaign_a: S6CampaignState = S6CampaignState.new()

	var first: Dictionary = S6CampaignActionEngine.execute(
		action,
		economy_a,
		campaign_a,
		1,
		0.4,
		config
	)

	var economy_b: S6EconomyState = S6EconomyState.new(
		"party",
		20000
	)

	var campaign_b: S6CampaignState = S6CampaignState.new()

	var second: Dictionary = S6CampaignActionEngine.execute(
		action,
		economy_b,
		campaign_b,
		1,
		0.4,
		config
	)

	_check(
		first["success"] == second["success"],
		"campaign determinism success mismatch"
	)

	_check(
		abs(
			float(first["influence"])
			- float(second["influence"])
		) <= EPSILON,
		"campaign determinism influence mismatch"
	)

	_check(
		int(first["cost"]) == int(second["cost"]),
		"campaign determinism cost mismatch"
	)

	_check(
		first["risk_class"] == second["risk_class"],
		"campaign determinism risk mismatch"
	)


func _test_campaign_isolation() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()

	var economy: S6EconomyState = S6EconomyState.new(
		"party",
		100000
	)

	var campaign: S6CampaignState = S6CampaignState.new()

	var action_a: S6CampaignAction = S6CampaignAction.new(
		"rally-a",
		S6CampaignAction.RALLY,
		"party",
		"c1",
		5000,
		1.0,
		0.2,
		1,
		1.0
	)

	var action_b: S6CampaignAction = S6CampaignAction.new(
		"rally-b",
		S6CampaignAction.RALLY,
		"party",
		"c2",
		5000,
		1.0,
		0.2,
		1,
		1.0
	)

	var result_a: Dictionary = S6CampaignActionEngine.execute(
		action_a,
		economy,
		campaign,
		1,
		0.5,
		config
	)

	_check(
		result_a["success"],
		"first isolated campaign action failed"
	)

	var saturation_c2: float = campaign.saturation.get_value(
		"party",
		"c2",
		"rally"
	)

	_check(
		abs(saturation_c2) <= EPSILON,
		"saturation leaked to another constituency"
	)

	var result_b: Dictionary = S6CampaignActionEngine.execute(
		action_b,
		economy,
		campaign,
		1,
		0.5,
		config
	)

	_check(
		result_b["success"],
		"second isolated campaign action failed"
	)


func _test_serialization() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()

	var economy: S6EconomyState = S6EconomyState.new(
		"party",
		50000
	)

	economy.add_business(
		S6Business.new(
			"b1",
			"c1",
			100000,
			5000,
			0.1,
			0.1,
			0.1
		)
	)

	economy.collect_income(
		1,
		config
	)

	var campaign: S6CampaignState = S6CampaignState.new()

	var action: S6CampaignAction = S6CampaignAction.new(
		"a1",
		S6CampaignAction.INTERVIEW,
		"party",
		"c1",
		2500,
		1.0,
		0.1,
		1,
		1.0
	)

	S6CampaignActionEngine.execute(
		action,
		economy,
		campaign,
		1,
		0.2,
		config
	)

	var economy_round_trip: S6EconomyState = (
		S6EconomyState.from_dictionary(
			economy.to_dictionary()
		)
	)

	var campaign_round_trip: S6CampaignState = (
		S6CampaignState.from_dictionary(
			campaign.to_dictionary()
		)
	)

	_check(
		economy_round_trip.is_valid(),
		"economy serialization round-trip invalid"
	)

	_check(
		campaign_round_trip.is_valid(),
		"campaign serialization round-trip invalid"
	)

	_check(
		economy_round_trip.party_id == economy.party_id,
		"economy party_id round-trip failed"
	)

	_check(
		economy_round_trip.ledger.balance
		== economy.ledger.balance,
		"economy balance round-trip failed"
	)

	_check(
		campaign_round_trip.effects.size()
		== campaign.effects.size(),
		"campaign effect count round-trip failed"
	)


func _test_anti_exploits() -> void:
	var config: S6EconomyConfig = S6EconomyConfig.new()

	var economy: S6EconomyState = S6EconomyState.new(
		"party",
		10000
	)

	var fundraising: S6FundraisingAction = (
		S6FundraisingAction.new(
			"fund",
			"party",
			10000,
			1000,
			0.5,
			1
		)
	)

	var first: S6FundraisingResult = economy.fundraise(
		fundraising,
		1,
		config
	)

	_check(
		first.success,
		"anti-exploit fundraising setup failed"
	)

	var same_turn: S6FundraisingResult = economy.fundraise(
		fundraising,
		1,
		config
	)

	_check(
		not same_turn.success,
		"same-turn infinite fundraising exploit"
	)

	var campaign: S6CampaignState = S6CampaignState.new()

	var expensive: S6CampaignAction = S6CampaignAction.new(
		"expensive",
		S6CampaignAction.RALLY,
		"party",
		"c1",
		999999999,
		1.0,
		0.2,
		1,
		1.0
	)

	var before: int = economy.ledger.balance

	var failed: Dictionary = S6CampaignActionEngine.execute(
		expensive,
		economy,
		campaign,
		1,
		0.5,
		config
	)

	_check(
		not failed["success"],
		"oversized campaign unexpectedly succeeded"
	)

	_check(
		economy.ledger.balance == before,
		"failed campaign changed money"
	)

	var negative_cost: S6CampaignAction = S6CampaignAction.new(
		"negative",
		S6CampaignAction.RALLY,
		"party",
		"c1",
		-100,
		1.0,
		0.2,
		1,
		1.0
	)

	_check(
		not negative_cost.is_valid(config),
		"negative campaign cost accepted"
	)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
