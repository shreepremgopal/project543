class_name S6IncomeEngine
extends RefCounted

static func collect_business_income(
	party_id: String,
	turn: int,
	businesses: Array[S6Business],
	ledger: S6MoneyLedger,
	config: S6EconomyConfig
) -> Dictionary:
	var result := {
		"success": true,
		"total_income": 0,
		"businesses_processed": 0,
		"errors": []
	}

	if party_id.strip_edges().is_empty():
		result["success"] = false
		result["errors"].append("party_id must not be empty")
		return result

	if turn < 1:
		result["success"] = false
		result["errors"].append("turn must be >= 1")
		return result

	if ledger == null:
		result["success"] = false
		result["errors"].append("ledger must not be null")
		return result

	if config == null or not config.is_valid():
		result["success"] = false
		result["errors"].append("invalid economy config")
		return result

	for business in businesses:
		if business == null:
			result["success"] = false
			result["errors"].append("null business")
			continue

		if not business.is_valid():
			result["success"] = false
			result["errors"].append_array(business.validate())
			continue

		result["businesses_processed"] += 1

		var income := business.calculate_income(config)

		if income <= 0:
			continue

		var accepted := ledger.receive(
			"business:%s" % business.business_id,
			income,
			turn,
			"Business revenue for turn %d" % turn,
			S6MoneyTransaction.TYPES.BUSINESS_REVENUE
		)

		if not accepted:
			result["success"] = false
			result["errors"].append(
				"failed to record business income for %s"
				% business.business_id
			)
			continue

		result["total_income"] += income

	return result
