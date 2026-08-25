class_name GeoGeometry
extends RefCounted


static func extract_points(geometry: Dictionary) -> Array:
	var geometry_type: String = str(
		geometry.get("type", "")
	)

	var coordinates: Variant = geometry.get(
		"coordinates",
		[]
	)

	var rings: Array = []

	if geometry_type == "Polygon":
		for ring: Variant in coordinates:
			rings.append(ring)

	elif geometry_type == "MultiPolygon":
		for polygon: Variant in coordinates:
			for ring: Variant in polygon:
				rings.append(ring)

	return rings
