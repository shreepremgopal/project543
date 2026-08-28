class_name S6EconomyState
extends RefCounted

const SCHEMA_VERSION := 1

var schema_version: int = SCHEMA_VERSION

var party_id: String
var ledger: S6MoneyLedger

var businesses: Array[S6Business] = []

var last_fundraising_turn: Dictionary = {}

func _init(
	party_id_value: String = "",
	initial_money: int = 0
) -> void:
	party_id = party_id_value
	ledger = S6MoneyLedger.new(initial_money)

func add_business(business: S6Business) -> bool:
	if business == null:
		return false

	if not business.is_valid():
		return false

	if get_business(business.business_id) != null:
		return false

	businesses.append(business)
	return true

func get_business(business_id: String) -> S6Business:
	for business in businesses:
		if business.business_id == business_id:
			return business

	return null

func remove_business(business_id: String) -> bool:
	for index in businesses.size():
		if businesses[index].business_id == business_id:
			businesses.remove_at(index)
			return true

	return false

func collect_income(
	turn: int,
	config: S6EconomyConfig
) -> Dictionary:
	return S6IncomeEngine.collect_business_income(
		party_id,
		turn,
		businesses,
		ledger,
		config
	)

func can_fundraise(
	action: S6FundraisingAction,
	turn: int
) -> bool:
	if action == null:
		return false

	if not action.is_valid():
		return false

	if action.party_id != party_id:
		return false

	if turn < 1:
		return false

	var last_turn: int = int(
		last_fundraising_turn.get(
			action.action_id,
			-1000000
		)
	)

	var required_gap: int = max(
		1,
		action.cooldown_turns
	)

	return turn >= last_turn + required_gap

func fundraise(
	action: S6FundraisingAction,
	turn: int,
	config: S6EconomyConfig
) -> S6FundraisingResult:
	var result := S6FundraisingResult.new()

	if action == null:
		result.reason = "action is null"
		return result

	result.action_id = action.action_id

	if not action.is_valid():
		result.reason = "invalid fundraising action"
		return result

	if action.party_id != party_id:
		result.reason = "fundraising party mismatch"
		return result

	if turn < 1:
		result.reason = "turn must be >= 1"
		return result

	if config == null or not config.is_valid():
		result.reason = "invalid economy config"
		return result

	if not can_fundraise(action, turn):
		result.reason = "fundraising cooldown active"
		return result

	var effective_cost := action.direct_cost

	if effective_cost > 0:
		if not ledger.spend(
			"fundraising:%s:cost" % action.action_id,
			effective_cost,
			turn,
			"Fundraising operating cost",
			S6MoneyTransaction.TYPES.FUNDRAISING
		):
			result.reason = "insufficient funds for fundraising cost"
			return result

	var proceeds := int(
		floor(
			float(action.gross_amount)
			* config.fundraising_efficiency
		)
	)

	if proceeds <= 0:
		if effective_cost > 0:
			ledger.receive(
				"fundraising:%s:refund" % action.action_id,
				effective_cost,
				turn,
				"Failed fundraising cost refund",
				S6MoneyTransaction.TYPES.REFUND
			)

		result.reason = "fundraising generated no proceeds"
		return result

	if not ledger.receive(
		"fundraising:%s" % action.action_id,
		proceeds,
		turn,
		"Fundraising proceeds",
		S6MoneyTransaction.TYPES.FUNDRAISING
	):
		if effective_cost > 0:
			ledger.receive(
				"fundraising:%s:refund" % action.action_id,
				effective_cost,
				turn,
				"Failed fundraising rollback",
				S6MoneyTransaction.TYPES.REFUND
			)

		result.reason = "failed to record fundraising proceeds"
		return result

	last_fundraising_turn[action.action_id] = turn

	result.success = true
	result.gross_amount = action.gross_amount
	result.direct_cost = effective_cost
	result.efficiency = config.fundraising_efficiency
	result.net_amount = proceeds - effective_cost
	result.risk_exposure = clamp(
		action.risk_amount
		* config.fundraising_risk_multiplier,
		0.0,
		1.0
	)
	result.reason = "fundraising completed"

	return result

func validate() -> Array[String]:
	var errors: Array[String] = []

	if schema_version != SCHEMA_VERSION:
		errors.append("unsupported economy schema version")

	if party_id.strip_edges().is_empty():
		errors.append("party_id must not be empty")

	if ledger == null:
		errors.append("ledger is null")
	else:
		errors.append_array(ledger.validate())

	var ids := {}

	for business in businesses:
		if business == null:
			errors.append("null business")
			continue

		errors.append_array(business.validate())

		if ids.has(business.business_id):
			errors.append(
				"duplicate business_id: %s"
				% business.business_id
			)

		ids[business.business_id] = true

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	var serialized_businesses: Array = []

	for business in businesses:
		serialized_businesses.append(
			business.to_dictionary()
		)

	return {
		"schema_version": schema_version,
		"party_id": party_id,
		"ledger": ledger.to_dictionary(),
		"businesses": serialized_businesses,
		"last_fundraising_turn": last_fundraising_turn.duplicate(true)
	}

static func from_dictionary(data: Dictionary) -> S6EconomyState:
	var result := S6EconomyState.new(
		String(data.get("party_id", "")),
		0
	)

	result.schema_version = int(
		data.get(
			"schema_version",
			SCHEMA_VERSION
		)
	)

	result.ledger = S6MoneyLedger.from_dictionary(
		data.get("ledger", {})
	)

	for item in data.get("businesses", []):
		result.businesses.append(
			S6Business.from_dictionary(item)
		)

	result.last_fundraising_turn = data.get(
		"last_fundraising_turn",
		{}
	).duplicate(true)

	return result
