class_name GISBounds
extends RefCounted


var min_lon := INF
var max_lon := -INF
var min_lat := INF
var max_lat := -INF


func include_coordinate(
	longitude: float,
	latitude: float
) -> void:
	min_lon = min(min_lon, longitude)
	max_lon = max(max_lon, longitude)

	min_lat = min(min_lat, latitude)
	max_lat = max(max_lat, latitude)


func is_valid() -> bool:
	return (
		min_lon != INF
		and max_lon != -INF
		and min_lat != INF
		and max_lat != -INF
	)


func get_center() -> Vector2:
	return Vector2(
		(min_lon + max_lon) * 0.5,
		(min_lat + max_lat) * 0.5
	)