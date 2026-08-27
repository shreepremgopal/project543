class_name PollingModel
extends RefCounted


enum Tier {
	BASIC,
	STANDARD,
	DEEP
}


static func cost(
	tier: Tier,
	config: PoliticalBalanceConfig
) -> int:
	match tier:
		Tier.BASIC:
			return config.poll_basic_cost
		Tier.STANDARD:
			return config.poll_standard_cost
		Tier.DEEP:
			return config.poll_deep_cost

	return config.poll_basic_cost


static func uncertainty(
	tier: Tier,
	config: PoliticalBalanceConfig
) -> float:
	match tier:
		Tier.BASIC:
			return config.poll_basic_uncertainty
		Tier.STANDARD:
			return config.poll_standard_uncertainty
		Tier.DEEP:
			return config.poll_deep_uncertainty

	return config.poll_basic_uncertainty


static func conduct_poll(
	constituency_id: String,
	turn: int,
	tier: Tier,
	truth: Dictionary,
	config: PoliticalBalanceConfig,
	seed: int
) -> Dictionary:
	if config == null or not config.is_valid():
		return {}

	var uncertainty_value := uncertainty(
		tier,
		config
	)

	var rng := RandomNumberGenerator.new()

	rng.seed = _context_seed(
		seed,
		constituency_id,
		turn,
		tier
	)

	var results := {}

	var party_ids: Array[String] = []

	for key in truth.keys():
		party_ids.append(String(key))

	party_ids.sort()

	for party_id in party_ids:
		var actual := clampf(
			float(truth[party_id]),
			0.0,
			1.0
		)

		var noise := rng.randf_range(
			-uncertainty_value,
			uncertainty_value
		)

		var estimate := clampf(
			actual + noise,
			0.0,
			1.0
		)

		results[party_id] = {
			"estimate": estimate,
			"lower": max(
				0.0,
				estimate - uncertainty_value
			),
			"upper": min(
				1.0,
				estimate + uncertainty_value
			),
			"confidence": 1.0 - uncertainty_value
		}

	return {
		"constituency_id": constituency_id,
		"turn": turn,
		"tier": Tier.keys()[tier],
		"cost": cost(tier, config),
		"uncertainty": uncertainty_value,
		"results": results,
		"freshness": "CURRENT",
		"polling_model_version": (
			PoliticalBalanceConfig.POLLING_MODEL_VERSION
		),
		"seed": seed
	}


static func charge(
	party_state: PartyState,
	tier: Tier,
	config: PoliticalBalanceConfig
) -> bool:
	if party_state == null:
		return false

	var amount := cost(
		tier,
		config
	)

	if party_state.money < amount:
		return false

	party_state.money -= amount

	return true


static func _context_seed(
	seed: int,
	constituency_id: String,
	turn: int,
	tier: Tier
) -> int:
	var text := (
		"%s|%s|%s|%s"
		% [
			seed,
			constituency_id,
			turn,
			int(tier)
		]
	)

	var digest := text.sha256_text()

	var value := 0

	for index in range(
		min(8, digest.length())
	):
		value = (
			(value << 4)
			+ _hex_value(
				digest[index]
			)
		)

	return value


static func _hex_value(
	character: String
) -> int:
	var characters := "0123456789abcdef"

	return characters.find(
		character.to_lower()
	)
