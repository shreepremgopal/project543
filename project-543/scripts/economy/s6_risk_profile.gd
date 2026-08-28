class_name S6RiskProfile
extends RefCounted

const LOW := "low"
const MEDIUM := "medium"
const HIGH := "high"

var action_risk: float
var target_vulnerability: float
var existing_exposure: float

func _init(
	action_risk_value: float = 0.0,
	target_vulnerability_value: float = 0.0,
	existing_exposure_value: float = 0.0
) -> void:
	action_risk = action_risk_value
	target_vulnerability = target_vulnerability_value
	existing_exposure = existing_exposure_value

func validate() -> Array[String]:
	var errors: Array[String] = []

	if not _valid(action_risk):
		errors.append("action_risk must be in [0, 1]")
	if not _valid(target_vulnerability):
		errors.append("target_vulnerability must be in [0, 1]")
	if not _valid(existing_exposure):
		errors.append("existing_exposure must be in [0, 1]")

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func calculate_exposure() -> float:
	var value := action_risk * (0.5 + target_vulnerability * 0.5)
	value += existing_exposure * 0.25
	return clamp(value, 0.0, 1.0)

func classify(config: S6EconomyConfig) -> String:
	var exposure := calculate_exposure()

	if exposure < config.low_risk_threshold:
		return LOW
	if exposure < config.medium_risk_threshold:
		return MEDIUM

	return HIGH

func _valid(value: float) -> bool:
	return is_finite(value) and value >= 0.0 and value <= 1.0
