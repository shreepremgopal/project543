class_name IdeologyProfile
extends RefCounted

const MIN_VALUE: float = -1.0
const MAX_VALUE: float = 1.0
const DIMENSIONS: Array[String] = [
	"economic_policy",
	"welfare",
	"social_policy",
	"governance",
	"environment",
	"national_policy"
]

var economic_policy: float
var welfare: float
var social_policy: float
var governance: float
var environment: float
var national_policy: float

func _init(
	economic_policy_value: float = 0.0,
	welfare_value: float = 0.0,
	social_policy_value: float = 0.0,
	governance_value: float = 0.0,
	environment_value: float = 0.0,
	national_policy_value: float = 0.0
) -> void:
	economic_policy = economic_policy_value
	welfare = welfare_value
	social_policy = social_policy_value
	governance = governance_value
	environment = environment_value
	national_policy = national_policy_value

func get_value(dimension: String) -> float:
	if not DIMENSIONS.has(dimension):
		return 0.0
	return float(get(dimension))

func validate() -> Array[String]:
	var errors: Array[String] = []
	for dimension in DIMENSIONS:
		var value: float = get_value(dimension)
		if not is_finite(value):
			errors.append("IdeologyProfile.%s must be finite; got %s" % [dimension, value])
		elif value < MIN_VALUE or value > MAX_VALUE:
			errors.append(
				"IdeologyProfile.%s=%s; expected [%s, %s]"
				% [dimension, value, MIN_VALUE, MAX_VALUE]
			)
	return errors

func is_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	var result: Dictionary = {}
	for dimension in DIMENSIONS:
		result[dimension] = get_value(dimension)
	return result

static func from_dictionary(data: Dictionary) -> IdeologyProfile:
	return IdeologyProfile.new(
		float(data.get("economic_policy", 0.0)),
		float(data.get("welfare", 0.0)),
		float(data.get("social_policy", 0.0)),
		float(data.get("governance", 0.0)),
		float(data.get("environment", 0.0)),
		float(data.get("national_policy", 0.0))
	)

func equals(other: IdeologyProfile) -> bool:
	return other != null and to_dictionary() == other.to_dictionary()
