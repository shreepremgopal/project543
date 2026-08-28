class_name S6MoneyTransaction
extends RefCounted

const TYPES := {
	"INCOME": "INCOME",
	"FUNDRAISING": "FUNDRAISING",
	"BUSINESS_REVENUE": "BUSINESS_REVENUE",
	"CAMPAIGN_SPEND": "CAMPAIGN_SPEND",
	"POLLING": "POLLING",
	"PENALTY": "PENALTY",
	"REFUND": "REFUND"
}

var transaction_id: String
var source: String
var amount: int
var turn: int
var reason: String
var transaction_type: String

func _init(
	source_value: String = "",
	amount_value: int = 0,
	turn_value: int = 1,
	reason_value: String = "",
	transaction_type_value: String = ""
) -> void:
	transaction_id = _make_id(
		source_value,
		amount_value,
		turn_value,
		reason_value,
		transaction_type_value
	)
	source = source_value
	amount = amount_value
	turn = turn_value
	reason = reason_value
	transaction_type = transaction_type_value

func validate() -> Array[String]:
	var errors: Array[String] = []

	if source.strip_edges().is_empty():
		errors.append("transaction source must not be empty")

	if amount == 0:
		errors.append("transaction amount must not be zero")

	if turn < 1:
		errors.append("transaction turn must be >= 1")

	if reason.strip_edges().is_empty():
		errors.append("transaction reason must not be empty")

	if not TYPES.values().has(transaction_type):
		errors.append("unknown transaction type: %s" % transaction_type)

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	return {
		"transaction_id": transaction_id,
		"source": source,
		"amount": amount,
		"turn": turn,
		"reason": reason,
		"transaction_type": transaction_type
	}

static func from_dictionary(data: Dictionary) -> S6MoneyTransaction:
	var result := S6MoneyTransaction.new(
		String(data.get("source", "")),
		int(data.get("amount", 0)),
		int(data.get("turn", 1)),
		String(data.get("reason", "")),
		String(data.get("transaction_type", ""))
	)
	result.transaction_id = String(data.get("transaction_id", result.transaction_id))
	return result

static func _make_id(
	source_value: String,
	amount_value: int,
	turn_value: int,
	reason_value: String,
	type_value: String
) -> String:
	var raw := "%s|%d|%d|%s|%s" % [
		source_value,
		amount_value,
		turn_value,
		reason_value,
		type_value
	]
	return "%s-%s" % [type_value, str(abs(raw.hash()))]
