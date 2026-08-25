class_name GISDataLoader
extends RefCounted


func load_seats(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("Could not open GIS data: " + path)
		return []

	var text := file.get_as_text()
	var json := JSON.new()

	var parse_result := json.parse(text)

	if parse_result != OK:
		push_error(
			"Could not parse GIS JSON: "
			+ json.get_error_message()
		)
		return []

	var data = json.data

	if typeof(data) != TYPE_DICTIONARY:
		push_error("GIS root is not a dictionary")
		return []

	if data.get("type", "") != "FeatureCollection":
		push_error("GIS root is not a FeatureCollection")
		return []

	var features = data.get("features", [])

	if typeof(features) != TYPE_ARRAY:
		push_error("GIS features is not an array")
		return []

	var seats: Array = []

	for feature in features:
		var properties: Dictionary = feature.get(
			"properties",
			{}
		)

		var geometry: Dictionary = feature.get(
			"geometry",
			{}
		)

		var seat := {
			"state_ut_name": properties.get(
				"state_ut_name",
				""
			),

			"ls_seat_name": properties.get(
				"ls_seat_name",
				""
			),

			"state_ut_code": properties.get(
				"state_ut_code",
				""
			),

			"ls_seat_code": properties.get(
				"ls_seat_code",
				""
			),

			"unique_id": properties.get(
				"unique_id",
				""
			),

			"geometry": geometry
		}

		seats.append(seat)

	return seats