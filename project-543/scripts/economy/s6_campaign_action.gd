class_name S6CampaignAction
extends RefCounted

const RALLY := "rally"
const INTERVIEW := "interview"
const MANIFESTO := "manifesto"
const CAMPAIGN := "campaign"

var action_id: String
var action_type: String
var party_id: String
var constituency_id: String

var base_cost: int
var intensity: float
var risk: float
var duration: int
var saturation_response: float

func _init(
	action_id_value: String = "",
	action_type_value: String = "",
	party_id_value: String = "",
	constituency_id_value: String = "",
	base_cost_value: int = 0,
	intensity_value: float = 1.0,
	risk_value: float = 0.0,
	duration_value: int = 1,
	saturation_response_value: float = 1.0
) -> void:
	action_id = action_id_value
	action_type = action_type_value
	party_id = party_id_value
	constituency_id = constituency_id_value
	base_cost = base_cost_value
	intensity = intensity_value
	risk = risk_value
	duration = duration_value
	saturation_response = saturation_response_value

func validate(config: S6EconomyConfig = null) -> Array[String]:
	var errors: Array[String] = []

	if action_id.strip_edges().is_empty():
		errors.append("action_id must not be empty")

	if not [
		RALLY,
		INTERVIEW,
		MANIFESTO,
		CAMPAIGN
	].has(action_type):
		errors.append("invalid action_type")

	if party_id.strip_edges().is_empty():
		errors.append("party_id must not be empty")

	if constituency_id.strip_edges().is_empty():
		errors.append("constituency_id must not be empty")

	if base_cost <= 0:
		errors.append("base_cost must be > 0")

	if not is_finite(intensity) or intensity <= 0.0:
		errors.append("intensity must be > 0")

	if not is_finite(risk) or risk < 0.0 or risk > 1.0:
		errors.append("risk must be in [0, 1]")

	if duration < 0:
		errors.append("duration must be >= 0")

	if not is_finite(saturation_response) or saturation_response <= 0.0:
		errors.append("saturation_response must be > 0")

	if config != null:
		if intensity < config.campaign_intensity_min:
			errors.append("intensity below configured minimum")

		if intensity > config.campaign_intensity_max:
			errors.append("intensity above configured maximum")

	return errors

func is_valid(config: S6EconomyConfig = null) -> bool:
	return validate(config).is_empty()

func action_family() -> String:
	return action_type

func to_dictionary() -> Dictionary:
	return {
		"action_id": action_id,
		"action_type": action_type,
		"party_id": party_id,
		"constituency_id": constituency_id,
		"base_cost": base_cost,
		"intensity": intensity,
		"risk": risk,
		"duration": duration,
		"saturation_response": saturation_response
	}

static func from_dictionary(data: Dictionary) -> S6CampaignAction:
	return S6CampaignAction.new(
		String(data.get("action_id", "")),
		String(data.get("action_type", "")),
		String(data.get("party_id", "")),
		String(data.get("constituency_id", "")),
		int(data.get("base_cost", 0)),
		float(data.get("intensity", 1.0)),
		float(data.get("risk", 0.0)),
		int(data.get("duration", 1)),
		float(data.get("saturation_response", 1.0))
	)

