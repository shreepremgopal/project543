class_name GeoGeometry
extends RefCounted


static func extract_points(geometry: Dictionary) -> Array:
	var rings: Array = []
	for polygon in extract_polygons(geometry):
		for ring in polygon:
			rings.append(ring)
	return rings


static func extract_polygons(geometry: Dictionary) -> Array:
	if geometry == null:
		return []

	var geometry_type := String(geometry.get("type", ""))
	var coordinates: Variant = geometry.get("coordinates", [])
	var polygons: Array = []

	if geometry_type == "Polygon":
		var polygon_rings: Array = []
		if coordinates is Array:
			for ring in coordinates:
				polygon_rings.append(ring)
			if not polygon_rings.is_empty():
				polygons.append(polygon_rings)

	elif geometry_type == "MultiPolygon":
		if coordinates is Array:
			for polygon in coordinates:
				var polygon_rings: Array = []
				for ring in polygon:
					polygon_rings.append(ring)
				if not polygon_rings.is_empty():
					polygons.append(polygon_rings)

	elif geometry_type == "GeometryCollection":
		var geometries: Variant = geometry.get("geometries", [])
		if geometries is Array:
			for child in geometries:
				if child is Dictionary:
					polygons.append_array(extract_polygons(child))

	return polygons
