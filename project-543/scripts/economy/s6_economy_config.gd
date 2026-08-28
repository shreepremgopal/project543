class_name S6EconomyConfig
extends RefCounted

const MODEL_VERSION := "economy-v0.1"
const CONFIG_VERSION := "economy-config-v0.1"

var business_income_multiplier: float = 1.0

var fundraising_efficiency: float = 0.80
var fundraising_risk_multiplier: float = 0.20

var campaign_intensity_min: float = 0.10
var campaign_intensity_max: float = 2.00

var saturation_floor: float = 0.10
var saturation_decay: float = 0.05

var low_risk_threshold: float = 0.25
var medium_risk_threshold: float = 0.60

var risk_exposure_cap: float = 1.0

var rally_base_influence: float = 0.120
var interview_base_influence: float = 0.070
var manifesto_base_influence: float = 0.090
var campaign_base_influence: float = 0.050

var rally_cost: int = 5000
var interview_cost: int = 2500
var manifesto_cost: int = 4000
var campaign_cost: int = 1500

var rally_risk: float = 0.30
var interview_risk: float = 0.20
var manifesto_risk: float = 0.10
var campaign_risk: float = 0.05

var rally_duration: int = 2
var interview_duration: int = 1
var manifesto_duration: int = 3
var campaign_duration: int = 1

var rally_max_saturation: float = 1.0
var interview_max_saturation: float = 1.0
var manifesto_max_saturation: float = 1.0
var campaign_max_saturation: float = 1.0

func validate() -> Array[String]:
	var errors: Array[String] = []

	if not is_finite(business_income_multiplier) or business_income_multiplier <= 0.0:
		errors.append("business_income_multiplier must be finite and > 0")

	if not is_finite(fundraising_efficiency) or fundraising_efficiency <= 0.0 or fundraising_efficiency > 1.0:
		errors.append("fundraising_efficiency must be in (0, 1]")

	if not is_finite(fundraising_risk_multiplier) or fundraising_risk_multiplier < 0.0:
		errors.append("fundraising_risk_multiplier must be >= 0")

	if campaign_intensity_min <= 0.0:
		errors.append("campaign_intensity_min must be > 0")

	if campaign_intensity_max < campaign_intensity_min:
		errors.append("campaign_intensity_max must be >= campaign_intensity_min")

	if saturation_floor <= 0.0 or saturation_floor > 1.0:
		errors.append("saturation_floor must be in (0, 1]")

	if saturation_decay <= 0.0 or saturation_decay > 1.0:
		errors.append("saturation_decay must be in (0, 1]")

	if low_risk_threshold < 0.0 or low_risk_threshold > 1.0:
		errors.append("low_risk_threshold must be in [0, 1]")

	if medium_risk_threshold < low_risk_threshold or medium_risk_threshold > 1.0:
		errors.append("medium_risk_threshold must be in [low_risk_threshold, 1]")

	if risk_exposure_cap <= 0.0:
		errors.append("risk_exposure_cap must be > 0")

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func action_base_cost(action_type: String) -> int:
	match action_type:
		"rally":
			return rally_cost
		"interview":
			return interview_cost
		"manifesto":
			return manifesto_cost
		"campaign":
			return campaign_cost
		_:
			return -1

func action_base_influence(action_type: String) -> float:
	match action_type:
		"rally":
			return rally_base_influence
		"interview":
			return interview_base_influence
		"manifesto":
			return manifesto_base_influence
		"campaign":
			return campaign_base_influence
		_:
			return -1.0

func action_risk(action_type: String) -> float:
	match action_type:
		"rally":
			return rally_risk
		"interview":
			return interview_risk
		"manifesto":
			return manifesto_risk
		"campaign":
			return campaign_risk
		_:
			return -1.0

func action_duration(action_type: String) -> int:
	match action_type:
		"rally":
			return rally_duration
		"interview":
			return interview_duration
		"manifesto":
			return manifesto_duration
		"campaign":
			return campaign_duration
		_:
			return -1

func action_max_saturation(action_type: String) -> float:
	match action_type:
		"rally":
			return rally_max_saturation
		"interview":
			return interview_max_saturation
		"manifesto":
			return manifesto_max_saturation
		"campaign":
			return campaign_max_saturation
		_:
			return -1.0
