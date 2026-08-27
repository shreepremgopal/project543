class_name ValidationError
extends RefCounted

var object_type: String
var object_id: String
var field: String
var actual_value: String
var expected: String
var message: String

func _init(
	object_type_value: String = "",
	object_id_value: String = "",
	field_value: String = "",
	actual_value_value: String = "",
	expected_value: String = "",
	message_value: String = ""
) -> void:
	object_type = object_type_value
	object_id = object_id_value
	field = field_value
	actual_value = actual_value_value
	expected = expected_value
	message = message_value

func to_dictionary() -> Dictionary:
	return {
		"object_type": object_type,
		"object_id": object_id,
		"field": field,
		"actual_value": actual_value,
		"expected": expected,
		"message": message
	}
