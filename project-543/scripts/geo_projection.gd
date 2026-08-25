class_name GeoProjection
extends RefCounted


var min_lon: float
var max_lon: float
var min_lat: float
var max_lat: float

var width: float
var height: float


func setup(
	min_longitude: float,
	max_longitude: float,
	min_latitude: float,
	max_latitude: float,
	map_width: float,
	map_height: float
) -> void:
	min_lon = min_longitude
	max_lon = max_longitude

	min_lat = min_latitude
	max_lat = max_latitude

	width = map_width
	height = map_height


func project(longitude: float, latitude: float) -> Vector2:
	var x := inverse_lerp(
		min_lon,
		max_lon,
		longitude
	)

	var y := inverse_lerp(
		max_lat,
		min_lat,
		latitude
	)

	return Vector2(
		x * width,
		y * height
	)
