class_name S6RiskExposure
extends RefCounted

var party_id: String
var constituency_id: String
var amount: float

func _init(
	party_id_value: String = "",
	constituency_id_value: String = "",
	amount_value: float = 0.0
) -> void:
	party_id = party_id_value
	constituency_id = constituency_id_value
	amount = amount_value

func validate() -> Array[String]:
	var errors: Array[String] = []

	if party_id.strip_edges().is_empty():
		errors.append("party_id must not be empty")

	if constituency_id.strip_edges().is_empty():
		errors.append("constituency_id must not be empty")

	if not is_finite(amount) or amount < 0.0 or amount > 1.0:
		errors.append("amount must be in [0, 1]")

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	return {
		"party_id": party_id,
		"constituency_id": constituency_id,
		"amount": amount
	}

static func from_dictionary(data: Dictionary) -> S6RiskExposure:
	return S6RiskExposure.new(
		String(data.get("party_id", "")),
		String(data.get("constituency_id", "")),
		float(data.get("amount", 0.0))
	)
