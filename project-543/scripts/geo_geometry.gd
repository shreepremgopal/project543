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


static func extract_polygons(geometry: Dictionary) -> Array:
	var geometry_type: String = str(
		geometry.get("type", "")
	)

	var coordinates: Variant = geometry.get(
		"coordinates",
		[]
	)

	var polygons: Array = []

	if geometry_type == "Polygon":
		var polygon_rings: Array = []

		for ring: Variant in coordinates:
			polygon_rings.append(ring)

		if not polygon_rings.is_empty():
			polygons.append(polygon_rings)

	elif geometry_type == "MultiPolygon":
		for polygon: Variant in coordinates:
			var polygon_rings: Array = []

			for ring: Variant in polygon:
				polygon_rings.append(ring)

			if not polygon_rings.is_empty():
				polygons.append(polygon_rings)

	return polygons
