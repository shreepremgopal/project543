class_name PartyState
extends RefCounted

var party_id: String
var money: int
var followers: int
var risk: float
var home_constituency_id: String
var base_support: Dictionary

func _init(
	party_id_value: String = "",
	money_value: int = 0,
	followers_value: int = 0,
	risk_value: float = 0.0,
	home_constituency_value: String = "",
	base_support_value: Dictionary = {}
) -> void:
	party_id = party_id_value
	money = money_value
	followers = followers_value
	risk = risk_value
	home_constituency_id = home_constituency_value
	base_support = base_support_value.duplicate(true)

func validate(constituency_registry: ConstituencyRegistry = null) -> Array[String]:
	var errors: Array[String] = []
	if party_id.strip_edges().is_empty():
		errors.append("PartyState.party_id must not be empty")
	if money < 0:
		errors.append("PartyState.money=%s; expected >= 0" % money)
	if followers < 0:
		errors.append("PartyState.followers=%s; expected >= 0" % followers)
	if not is_finite(risk) or risk < 0.0 or risk > 1.0:
		errors.append("PartyState.risk=%s; expected [0, 1]" % risk)

	if not home_constituency_id.strip_edges().is_empty():
		if constituency_registry != null and not constituency_registry.has(home_constituency_id):
			errors.append(
				"PartyState.home_constituency_id references unknown constituency '%s'"
				% home_constituency_id
			)

	for constituency_id in base_support:
		var support: float = float(base_support[constituency_id])
		if not is_finite(support) or support < 0.0 or support > 1.0:
			errors.append(
				"PartyState.base_support.%s=%s; expected [0, 1]"
				% [constituency_id, support]
			)
		if constituency_registry != null and not constituency_registry.has(String(constituency_id)):
			errors.append(
				"PartyState.base_support references unknown constituency '%s'"
				% constituency_id
			)
	return errors

func is_valid(constituency_registry: ConstituencyRegistry = null) -> bool:
	return validate(constituency_registry).is_empty()

func to_dictionary() -> Dictionary:
	var support: Dictionary = {}
	var ids: Array[String] = []
	for constituency_id in base_support:
		ids.append(String(constituency_id))
	ids.sort()
	for constituency_id in ids:
		support[constituency_id] = float(base_support[constituency_id])

	return {
		"party_id": party_id,
		"money": money,
		"followers": followers,
		"risk": risk,
		"home_constituency_id": home_constituency_id,
		"base_support": support
	}

static func from_dictionary(data: Dictionary) -> PartyState:
	return PartyState.new(
		String(data.get("party_id", "")),
		int(data.get("money", 0)),
		int(data.get("followers", 0)),
		float(data.get("risk", 0.0)),
		String(data.get("home_constituency_id", "")),
		data.get("base_support", {})
	)
