class_name S6Business
extends RefCounted

const STATUS_ACTIVE := "active"
const STATUS_INACTIVE := "inactive"

var business_id: String
var constituency_id: String

var capital_value: int
var operating_income: int

var volatility: float
var political_exposure: float
var risk_exposure: float

var status: String

func _init(
	business_id_value: String = "",
	constituency_id_value: String = "",
	capital_value_value: int = 0,
	operating_income_value: int = 0,
	volatility_value: float = 0.0,
	political_exposure_value: float = 0.0,
	risk_exposure_value: float = 0.0,
	status_value: String = STATUS_ACTIVE
) -> void:
	business_id = business_id_value
	constituency_id = constituency_id_value
	capital_value = capital_value_value
	operating_income = operating_income_value
	volatility = volatility_value
	political_exposure = political_exposure_value
	risk_exposure = risk_exposure_value
	status = status_value

func validate() -> Array[String]:
	var errors: Array[String] = []

	if business_id.strip_edges().is_empty():
		errors.append("business_id must not be empty")

	if constituency_id.strip_edges().is_empty():
		errors.append("constituency_id must not be empty")

	if capital_value < 0:
		errors.append("capital_value must be >= 0")

	if operating_income < 0:
		errors.append("operating_income must be >= 0")

	if not _valid_ratio(volatility):
		errors.append("volatility must be in [0, 1]")

	if not _valid_ratio(political_exposure):
		errors.append("political_exposure must be in [0, 1]")

	if not _valid_ratio(risk_exposure):
		errors.append("risk_exposure must be in [0, 1]")

	if status != STATUS_ACTIVE and status != STATUS_INACTIVE:
		errors.append("invalid business status")

	return errors

func is_valid() -> bool:
	return validate().is_empty()

func is_active() -> bool:
	return status == STATUS_ACTIVE

func calculate_income(config: S6EconomyConfig) -> int:
	if not is_active():
		return 0

	var stability_factor := 1.0 - volatility * 0.5
	var exposure_factor := 1.0 - political_exposure * 0.20
	var risk_factor := 1.0 - risk_exposure * 0.25

	var result := (
		float(operating_income)
		* config.business_income_multiplier
		* stability_factor
		* exposure_factor
		* risk_factor
	)

	return max(0, int(floor(result)))

func to_dictionary() -> Dictionary:
	return {
		"business_id": business_id,
		"constituency_id": constituency_id,
		"capital_value": capital_value,
		"operating_income": operating_income,
		"volatility": volatility,
		"political_exposure": political_exposure,
		"risk_exposure": risk_exposure,
		"status": status
	}

static func from_dictionary(data: Dictionary) -> S6Business:
	return S6Business.new(
		String(data.get("business_id", "")),
		String(data.get("constituency_id", "")),
		int(data.get("capital_value", 0)),
		int(data.get("operating_income", 0)),
		float(data.get("volatility", 0.0)),
		float(data.get("political_exposure", 0.0)),
		float(data.get("risk_exposure", 0.0)),
		String(data.get("status", STATUS_ACTIVE))
	)

static func _valid_ratio(value: float) -> bool:
	return is_finite(value) and value >= 0.0 and value <= 1.0
