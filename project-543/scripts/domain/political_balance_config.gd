class_name PoliticalBalanceConfig
extends RefCounted

const MODEL_VERSION: String = "political-v0.1"
const CONFIG_VERSION: String = "political-config-v0.1"
const POLLING_MODEL_VERSION: String = "polling-v0.1"

const DEFAULT_ALIGNMENT_LAMBDA := 2.0

const DEFAULT_POLL_BASIC_COST := 10000
const DEFAULT_POLL_STANDARD_COST := 25000
const DEFAULT_POLL_DEEP_COST := 50000

const DEFAULT_POLL_BASIC_UNCERTAINTY := 0.12
const DEFAULT_POLL_STANDARD_UNCERTAINTY := 0.07
const DEFAULT_POLL_DEEP_UNCERTAINTY := 0.035

const DEFAULT_STALE_AFTER_TURNS := 3

const DEFAULT_SUPPORT_TOLERANCE := 0.000001
const DEFAULT_SALIENCE_TOLERANCE := 0.000001
const DEFAULT_DISTRIBUTION_TOLERANCE := 0.000001

var alignment_lambda: float = DEFAULT_ALIGNMENT_LAMBDA

var poll_basic_cost: int = DEFAULT_POLL_BASIC_COST
var poll_standard_cost: int = DEFAULT_POLL_STANDARD_COST
var poll_deep_cost: int = DEFAULT_POLL_DEEP_COST

var poll_basic_uncertainty: float = DEFAULT_POLL_BASIC_UNCERTAINTY
var poll_standard_uncertainty: float = DEFAULT_POLL_STANDARD_UNCERTAINTY
var poll_deep_uncertainty: float = DEFAULT_POLL_DEEP_UNCERTAINTY

var stale_after_turns: int = DEFAULT_STALE_AFTER_TURNS

var support_tolerance: float = DEFAULT_SUPPORT_TOLERANCE
var salience_tolerance: float = DEFAULT_SALIENCE_TOLERANCE
var distribution_tolerance: float = DEFAULT_DISTRIBUTION_TOLERANCE


func validate() -> Array[String]:
	var errors: Array[String] = []

	if not is_finite(alignment_lambda) or alignment_lambda <= 0.0:
		errors.append("alignment_lambda must be finite and > 0")

	if poll_basic_cost < 0:
		errors.append("poll_basic_cost must be >= 0")

	if poll_standard_cost < 0:
		errors.append("poll_standard_cost must be >= 0")

	if poll_deep_cost < 0:
		errors.append("poll_deep_cost must be >= 0")

	if poll_basic_cost > poll_standard_cost:
		errors.append("Basic polling must not cost more than Standard")

	if poll_standard_cost > poll_deep_cost:
		errors.append("Standard polling must not cost more than Deep")

	if not _valid_uncertainty(poll_basic_uncertainty):
		errors.append("Invalid Basic polling uncertainty")

	if not _valid_uncertainty(poll_standard_uncertainty):
		errors.append("Invalid Standard polling uncertainty")

	if not _valid_uncertainty(poll_deep_uncertainty):
		errors.append("Invalid Deep polling uncertainty")

	if poll_basic_uncertainty < poll_standard_uncertainty:
		errors.append("Basic polling must not be more accurate than Standard")

	if poll_standard_uncertainty < poll_deep_uncertainty:
		errors.append("Standard polling must not be more accurate than Deep")

	if stale_after_turns < 1:
		errors.append("stale_after_turns must be >= 1")

	if support_tolerance <= 0.0:
		errors.append("support_tolerance must be > 0")

	if salience_tolerance <= 0.0:
		errors.append("salience_tolerance must be > 0")

	if distribution_tolerance <= 0.0:
		errors.append("distribution_tolerance must be > 0")

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func to_dictionary() -> Dictionary:
	return {
		"schema_version": 1,
		"model_version": MODEL_VERSION,
		"config_version": CONFIG_VERSION,
		"polling_model_version": POLLING_MODEL_VERSION,
		"alignment_lambda": alignment_lambda,
		"poll_basic_cost": poll_basic_cost,
		"poll_standard_cost": poll_standard_cost,
		"poll_deep_cost": poll_deep_cost,
		"poll_basic_uncertainty": poll_basic_uncertainty,
		"poll_standard_uncertainty": poll_standard_uncertainty,
		"poll_deep_uncertainty": poll_deep_uncertainty,
		"stale_after_turns": stale_after_turns,
		"support_tolerance": support_tolerance,
		"salience_tolerance": salience_tolerance,
		"distribution_tolerance": distribution_tolerance
	}


static func from_dictionary(data: Dictionary) -> PoliticalBalanceConfig:
	var config := PoliticalBalanceConfig.new()

	config.alignment_lambda = float(
		data.get("alignment_lambda", DEFAULT_ALIGNMENT_LAMBDA)
	)

	config.poll_basic_cost = int(
		data.get("poll_basic_cost", DEFAULT_POLL_BASIC_COST)
	)

	config.poll_standard_cost = int(
		data.get("poll_standard_cost", DEFAULT_POLL_STANDARD_COST)
	)

	config.poll_deep_cost = int(
		data.get("poll_deep_cost", DEFAULT_POLL_DEEP_COST)
	)

	config.poll_basic_uncertainty = float(
		data.get(
			"poll_basic_uncertainty",
			DEFAULT_POLL_BASIC_UNCERTAINTY
		)
	)

	config.poll_standard_uncertainty = float(
		data.get(
			"poll_standard_uncertainty",
			DEFAULT_POLL_STANDARD_UNCERTAINTY
		)
	)

	config.poll_deep_uncertainty = float(
		data.get(
			"poll_deep_uncertainty",
			DEFAULT_POLL_DEEP_UNCERTAINTY
		)
	)

	config.stale_after_turns = int(
		data.get("stale_after_turns", DEFAULT_STALE_AFTER_TURNS)
	)

	config.support_tolerance = float(
		data.get(
			"support_tolerance",
			DEFAULT_SUPPORT_TOLERANCE
		)
	)

	config.salience_tolerance = float(
		data.get(
			"salience_tolerance",
			DEFAULT_SALIENCE_TOLERANCE
		)
	)

	config.distribution_tolerance = float(
		data.get(
			"distribution_tolerance",
			DEFAULT_DISTRIBUTION_TOLERANCE
		)
	)

	return config


static func load_json(path: String) -> PoliticalBalanceConfig:
	if not FileAccess.file_exists(path):
		push_error("Political balance config missing: " + path)
		return PoliticalBalanceConfig.new()

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not open political balance config: " + path)
		return PoliticalBalanceConfig.new()

	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())

	if error != OK:
		push_error(
			"Political balance config parse error: %s"
			% parser.get_error_message()
		)
		return PoliticalBalanceConfig.new()

	if typeof(parser.data) != TYPE_DICTIONARY:
		push_error("Political balance config root must be a Dictionary")
		return PoliticalBalanceConfig.new()

	return from_dictionary(parser.data)


static func _valid_uncertainty(value: float) -> bool:
	return (
		is_finite(value)
		and value >= 0.0
		and value < 1.0
	)
