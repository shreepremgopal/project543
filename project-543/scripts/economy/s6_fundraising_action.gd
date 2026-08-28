class_name S6FundraisingAction
extends RefCounted

var action_id: String
var party_id: String
var gross_amount: int
var direct_cost: int
var risk_amount: float
var cooldown_turns: int

func _init(
	action_id_value: String = "",
	party_id_value: String = "",
	gross_amount_value: int = 0,
	direct_cost_value: int = 0,
	risk_amount_value: float = 0.0,
	cooldown_turns_value: int = 1
) -> void:
	action_id = action_id_value
	party_id = party_id_value
	gross_amount = gross_amount_value
	direct_cost = direct_cost_value
	risk_amount = risk_amount_value
	cooldown_turns = cooldown_turns_value

func validate() -> Array[String]:
	var errors: Array[String] = []

	if action_id.strip_edges().is_empty():
		errors.append("fundraising action_id must not be empty")
	if party_id.strip_edges().is_empty():
		errors.append("fundraising party_id must not be empty")
	if gross_amount <= 0:
		errors.append("gross_amount must be > 0")
	if direct_cost < 0:
		errors.append("direct_cost must be >= 0")
	if not is_finite(risk_amount) or risk_amount < 0.0 or risk_amount > 1.0:
		errors.append("risk_amount must be in [0, 1]")
	if cooldown_turns < 0:
		errors.append("cooldown_turns must be >= 0")

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	return {
		"action_id": action_id,
		"party_id": party_id,
		"gross_amount": gross_amount,
		"direct_cost": direct_cost,
		"risk_amount": risk_amount,
		"cooldown_turns": cooldown_turns
	}

static func from_dictionary(data: Dictionary) -> S6FundraisingAction:
	return S6FundraisingAction.new(
		String(data.get("action_id", "")),
		String(data.get("party_id", "")),
		int(data.get("gross_amount", 0)),
		int(data.get("direct_cost", 0)),
		float(data.get("risk_amount", 0.0)),
		int(data.get("cooldown_turns", 1))
	)
