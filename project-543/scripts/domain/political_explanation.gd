class_name PoliticalExplanation
extends RefCounted

var constituency_id := ""
var party_id := ""

var model_version := PoliticalBalanceConfig.MODEL_VERSION
var config_version := PoliticalBalanceConfig.CONFIG_VERSION

var base_support := 0.0
var responsive_population := 0.0
var constituency_affinity := 0.0
var potential := 0.0
var normalized_support := 0.0

var fingerprint := ""


func calculate_potential() -> float:
	potential = (
		base_support
		+ responsive_population
		* constituency_affinity
	)

	return potential


func reconstructs(
	tolerance: float
) -> bool:
	var reconstructed := (
		base_support
		+ responsive_population
		* constituency_affinity
	)

	return abs(
		reconstructed - potential
	) <= tolerance


func to_dictionary() -> Dictionary:
	return {
		"constituency_id": constituency_id,
		"party_id": party_id,
		"model_version": model_version,
		"config_version": config_version,
		"base_support": base_support,
		"responsive_population": responsive_population,
		"constituency_affinity": constituency_affinity,
		"potential": potential,
		"normalized_support": normalized_support,
		"fingerprint": fingerprint
	}
