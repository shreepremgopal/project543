class_name S6FundraisingResult
extends RefCounted

var success: bool = false
var action_id: String = ""
var gross_amount: int = 0
var direct_cost: int = 0
var efficiency: float = 0.0
var net_amount: int = 0
var risk_exposure: float = 0.0
var reason: String = ""

func to_dictionary() -> Dictionary:
	return {
		"success": success,
		"action_id": action_id,
		"gross_amount": gross_amount,
		"direct_cost": direct_cost,
		"efficiency": efficiency,
		"net_amount": net_amount,
		"risk_exposure": risk_exposure,
		"reason": reason
	}
