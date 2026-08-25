extends Node2D


const DATA_PATH := "res://data/generated/india_ls_seats_543_runtime.geojson"

const MAP_WIDTH := 1200.0
const MAP_HEIGHT := 1000.0


var seats: Array = []
var projection: GeoProjection


func _ready() -> void:
	var loader := GISDataLoader.new()

	seats = loader.load_seats(DATA_PATH)

	print("GIS seats loaded: ", seats.size())

	assert(
		seats.size() == 543,
		"Project 543 requires exactly 543 constituencies."
	)
	if not _validate_seats():
		return

	_build_projection()
	queue_redraw()

func _build_projection() -> void:
	var bounds := GISBounds.new()

	for seat in seats:
		var geometry: Dictionary = seat["geometry"]

		var rings := GeoGeometry.extract_points(
			geometry
		)

		for ring in rings:
			for coordinate in ring:
				if coordinate.size() < 2:
					continue

				var longitude := float(
					coordinate[0]
				)

				var latitude := float(
					coordinate[1]
				)

				bounds.include_coordinate(
					longitude,
					latitude
				)

	if not bounds.is_valid():
		push_error("Could not calculate GIS bounds")
		return

	print(
		"Bounds: ",
		bounds.min_lon,
		", ",
		bounds.min_lat,
		" -> ",
		bounds.max_lon,
		", ",
		bounds.max_lat
	)

	projection = GeoProjection.new()

	projection.setup(
		bounds.min_lon,
		bounds.max_lon,
		bounds.min_lat,
		bounds.max_lat,
		MAP_WIDTH,
		MAP_HEIGHT
	)
func _draw() -> void:
	if projection == null:
		return

	for seat in seats:
		var geometry: Dictionary = seat["geometry"]

		var rings := GeoGeometry.extract_points(
			geometry
		)

		for ring in rings:
			var points := PackedVector2Array()

			for coordinate in ring:
				if coordinate.size() < 2:
					continue

				var longitude := float(
					coordinate[0]
				)

				var latitude := float(
					coordinate[1]
				)

				points.append(
					projection.project(
						longitude,
						latitude
					)
				)

			if points.size() >= 2:
				draw_polyline(
					points,
					Color.WHITE,
					1.0,
					true
				)
func _validate_seats() -> bool:
	var ids := {}

	for seat in seats:
		var unique_id: String = str(
			seat["unique_id"]
		)

		if unique_id.is_empty():
			push_error("Seat has empty unique_id")
			return false

		if ids.has(unique_id):
			push_error(
				"Duplicate unique_id: "
				+ unique_id
			)
			return false

		ids[unique_id] = true

	print(
		"Unique seat IDs validated: ",
		ids.size()
	)

	return ids.size() == 543
