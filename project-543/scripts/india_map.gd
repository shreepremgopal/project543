extends Node2D


signal constituency_selected(seat: Dictionary)
signal constituency_hovered(seat: Dictionary)
signal constituency_cleared()


const DATA_PATH := "res://data/generated/india_ls_seats_543_runtime.geojson"

# Canonical map width.
# Height is calculated from the actual geographic bounds.
const MAP_WIDTH := 1600.0

# Screen-space behaviour.
const FIT_PADDING := 32.0
const MIN_ZOOM := 1.0
const MAX_ZOOM := 12.0
const ZOOM_FACTOR := 1.15

# Interaction.
const PAN_BUTTON := MOUSE_BUTTON_MIDDLE

# Rendering.
const BASE_LINE_WIDTH := 1.0
const HOVER_LINE_WIDTH := 2.0
const SELECTED_LINE_WIDTH := 3.0

const MAP_LINE_COLOR := Color(0.82, 0.86, 0.92, 0.92)
const MAP_HOVER_COLOR := Color(0.35, 0.78, 1.0, 1.0)
const MAP_SELECTED_COLOR := Color(1.0, 0.78, 0.22, 1.0)

const MAP_BACKGROUND_COLOR := Color(0.035, 0.055, 0.09, 1.0)


var seats: Array = []

var projection: GeoProjection

# Cached projected geometry.
# Each entry:
# {
#     "seat": Dictionary,
#     "polygons": Array[Array[PackedVector2Array]],
#     "bounds": Rect2
# }
var seat_shapes: Array = []


var map_size := Vector2.ZERO

# Fit scale required to show the complete map.
var fit_scale := 1.0

# User zoom multiplier.
var zoom_level := MIN_ZOOM

# Actual screen scale.
var view_scale := 1.0


var selected_seat_index := -1
var hovered_seat_index := -1

var is_panning := false
var last_mouse_position := Vector2.ZERO


func _ready() -> void:
	set_process_input(true)

	var loader := GISDataLoader.new()

	seats = loader.load_seats(DATA_PATH)

	print("GIS seats loaded: ", seats.size())

	assert(
		seats.size() == 543,
		"Project 543 requires exactly 543 constituencies."
	)

	if not _validate_seats():
		return

	if not _build_projection():
		return

	_build_geometry_cache()

	_update_view_transform(true)
	var panel := get_node_or_null(
		"HUD/Panel"
	)

	if panel != null:
		constituency_selected.connect(
			panel.show_constituency
		)

		constituency_cleared.connect(
			panel.clear_constituency
		)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("_handle_viewport_resized")


func _handle_viewport_resized() -> void:
	if projection == null:
		return

	_update_view_transform(true)
	queue_redraw()


func _build_projection() -> bool:
	var bounds := GISBounds.new()

	for seat in seats:
		var geometry: Dictionary = seat["geometry"]

		var polygons := GeoGeometry.extract_polygons(
			geometry
		)

		for polygon in polygons:
			for ring in polygon:
				for coordinate in ring:
					if coordinate.size() < 2:
						continue

					var longitude := float(coordinate[0])
					var latitude := float(coordinate[1])

					bounds.include_coordinate(
						longitude,
						latitude
					)

	if not bounds.is_valid():
		push_error("Could not calculate GIS bounds")
		return false

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

	# Preserve the actual geographic aspect ratio.
	#
	# We do NOT force the map into an arbitrary 1200x1000 rectangle.
	var longitude_range := bounds.max_lon - bounds.min_lon
	var latitude_range := bounds.max_lat - bounds.min_lat

	if longitude_range <= 0.0 or latitude_range <= 0.0:
		push_error("Invalid GIS bounds range")
		return false

	var map_height := (
		MAP_WIDTH
		* latitude_range
		/ longitude_range
	)

	map_size = Vector2(
		MAP_WIDTH,
		map_height
	)

	projection = GeoProjection.new()

	projection.setup(
		bounds.min_lon,
		bounds.max_lon,
		bounds.min_lat,
		bounds.max_lat,
		map_size.x,
		map_size.y
	)

	print(
		"Canonical map size: ",
		map_size
	)

	return true


func _build_geometry_cache() -> void:
	seat_shapes.clear()

	for seat in seats:
		var projected_polygons: Array = []
		var combined_bounds := Rect2()

		var first_bounds := true

		var geometry: Dictionary = seat["geometry"]

		var polygons := GeoGeometry.extract_polygons(
			geometry
		)

		for polygon in polygons:
			var projected_rings: Array = []

			for ring in polygon:
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

				if points.size() >= 3:
					projected_rings.append(points)

					var ring_rect := _get_points_bounds(
						points
					)

					if first_bounds:
						combined_bounds = ring_rect
						first_bounds = false
					else:
						combined_bounds = combined_bounds.merge(
							ring_rect
						)

			if not projected_rings.is_empty():
				projected_polygons.append(
					projected_rings
				)

		seat_shapes.append(
			{
				"seat": seat,
				"polygons": projected_polygons,
				"bounds": combined_bounds
			}
		)

	print(
		"Geometry cache built: ",
		seat_shapes.size(),
		" constituencies"
	)


func _get_points_bounds(
	points: PackedVector2Array
) -> Rect2:
	if points.is_empty():
		return Rect2()

	var min_point := points[0]
	var max_point := points[0]

	for point in points:
		min_point.x = min(min_point.x, point.x)
		min_point.y = min(min_point.y, point.y)

		max_point.x = max(max_point.x, point.x)
		max_point.y = max(max_point.y, point.y)

	return Rect2(
		min_point,
		max_point - min_point
	)


func _update_view_transform(
	reset_zoom: bool = false
) -> void:
	var viewport_size := get_viewport_rect().size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var available_size := viewport_size - Vector2.ONE * (
		FIT_PADDING * 2.0
	)

	if available_size.x <= 0.0 or available_size.y <= 0.0:
		return

	fit_scale = min(
		available_size.x / map_size.x,
		available_size.y / map_size.y
	)

	if fit_scale <= 0.0:
		fit_scale = 1.0

	if reset_zoom:
		zoom_level = MIN_ZOOM

	_apply_zoom_and_center()


func _apply_zoom_and_center() -> void:
	var viewport_size := get_viewport_rect().size

	view_scale = fit_scale * zoom_level

	scale = Vector2.ONE * view_scale

	position = (
		viewport_size * 0.5
		- map_size * view_scale * 0.5
	)

	_clamp_map_position()


func _clamp_map_position() -> void:
	var viewport_size := get_viewport_rect().size
	var rendered_size := map_size * view_scale

	var min_position := Vector2.ZERO
	var max_position := Vector2.ZERO

	if rendered_size.x <= viewport_size.x:
		var centered_x := (
			viewport_size.x
			- rendered_size.x
		) * 0.5

		min_position.x = centered_x
		max_position.x = centered_x
	else:
		min_position.x = (
			viewport_size.x
			- rendered_size.x
		)
		max_position.x = 0.0

	if rendered_size.y <= viewport_size.y:
		var centered_y := (
			viewport_size.y
			- rendered_size.y
		) * 0.5

		min_position.y = centered_y
		max_position.y = centered_y
	else:
		min_position.y = (
			viewport_size.y
			- rendered_size.y
		)
		max_position.y = 0.0

	position.x = clampf(
		position.x,
		min_position.x,
		max_position.x
	)

	position.y = clampf(
		position.y,
		min_position.y,
		max_position.y
	)


func _input(event: InputEvent) -> void:
	if projection == null:
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
		return

	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
		return

	if event is InputEventKey:
		_handle_key(event)

func _handle_mouse_button(
	event: InputEventMouseButton
) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if event.pressed:
			_zoom_at(
				event.position,
				ZOOM_FACTOR
			)
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if event.pressed:
			_zoom_at(
				event.position,
				1.0 / ZOOM_FACTOR
			)
		return

	if event.button_index == PAN_BUTTON:
		is_panning = event.pressed

		if event.pressed:
			last_mouse_position = event.position

		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed:
			_reset_view()
			return

		if event.pressed:
			_select_at_screen_position(
				event.position
			)

		return


func _handle_mouse_motion(
	event: InputEventMouseMotion
) -> void:
	var screen_position := event.position

	if is_panning:
		var delta := (
			screen_position
			- last_mouse_position
		)

		position += delta

		_clamp_map_position()

		last_mouse_position = screen_position

		queue_redraw()

		return

	_update_hover(
		screen_position
	)


func _handle_key(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_HOME:
			_reset_view()

		KEY_EQUAL:
			_zoom_at(
				get_viewport_rect().size * 0.5,
				ZOOM_FACTOR
			)

		KEY_PLUS:
			_zoom_at(
				get_viewport_rect().size * 0.5,
				ZOOM_FACTOR
			)

		KEY_MINUS:
			_zoom_at(
				get_viewport_rect().size * 0.5,
				1.0 / ZOOM_FACTOR
			)


func _zoom_at(
	screen_position: Vector2,
	factor: float
) -> void:
	var old_scale := view_scale

	var new_zoom := clampf(
		zoom_level * factor,
		MIN_ZOOM,
		MAX_ZOOM
	)

	if is_equal_approx(
		new_zoom,
		zoom_level
	):
		return

	# Convert the cursor from screen space
	# into canonical map space BEFORE changing scale.
	var map_point := (
		screen_position - position
	) / old_scale

	zoom_level = new_zoom
	view_scale = fit_scale * zoom_level

	scale = Vector2.ONE * view_scale

	# Keep the geographic point underneath
	# the cursor stationary while zooming.
	position = (
		screen_position
		- map_point * view_scale
	)

	_clamp_map_position()

	queue_redraw()


func _reset_view() -> void:
	zoom_level = MIN_ZOOM
	_apply_zoom_and_center()

	queue_redraw()


func _select_at_screen_position(
	screen_position: Vector2
) -> void:
	var seat_index := _find_seat_at_screen_position(
		screen_position
	)

	if seat_index == -1:
		selected_seat_index = -1

		constituency_cleared.emit()

		queue_redraw()

		return

	selected_seat_index = seat_index

	var seat: Dictionary = seat_shapes[
		seat_index
	]["seat"]

	constituency_selected.emit(
		seat
	)

	queue_redraw()


func _update_hover(
	screen_position: Vector2
) -> void:
	var seat_index := _find_seat_at_screen_position(
		screen_position
	)

	if seat_index == hovered_seat_index:
		return

	hovered_seat_index = seat_index

	if hovered_seat_index == -1:
		queue_redraw()
		return

	var seat: Dictionary = seat_shapes[
		hovered_seat_index
	]["seat"]

	constituency_hovered.emit(
		seat
	)

	queue_redraw()


func _find_seat_at_screen_position(
	screen_position: Vector2
) -> int:
	if seat_shapes.is_empty():
		return -1

	# Convert screen coordinates into map-local
	# coordinates using the inverse of our
	# current uniform transform.
	var map_position := (
		screen_position - position
	) / view_scale

	# Test in reverse draw order so later shapes
	# have deterministic priority when boundaries
	# touch.
	for index in range(
		seat_shapes.size() - 1,
		-1,
		-1
	):
		var entry: Dictionary = seat_shapes[index]

		var bounds: Rect2 = entry["bounds"]

		if not bounds.has_point(map_position):
			continue

		var polygons: Array = entry["polygons"]

		for polygon in polygons:
			if polygon.is_empty():
				continue

			var outer_ring: PackedVector2Array = (
				polygon[0]
			)

			if not Geometry2D.is_point_in_polygon(
				map_position,
				outer_ring
			):
				continue

			# GeoJSON Polygon rings after the first
			# are holes. If the point is inside a hole,
			# it does not belong to this polygon.
			var inside_hole := false

			for hole_index in range(
				1,
				polygon.size()
			):
				var hole_ring: PackedVector2Array = (
					polygon[hole_index]
				)

				if Geometry2D.is_point_in_polygon(
					map_position,
					hole_ring
				):
					inside_hole = true
					break

			if not inside_hole:
				return index

	return -1


func _draw() -> void:
	# Background.


	if projection == null:
		return

	for index in seat_shapes.size():
		var entry: Dictionary = seat_shapes[index]

		var polygons: Array = entry["polygons"]

		var line_color := MAP_LINE_COLOR
		var line_width := BASE_LINE_WIDTH

		if index == hovered_seat_index:
			line_color = MAP_HOVER_COLOR
			line_width = HOVER_LINE_WIDTH

		if index == selected_seat_index:
			line_color = MAP_SELECTED_COLOR
			line_width = SELECTED_LINE_WIDTH

		for polygon in polygons:
			for ring in polygon:
				var points: PackedVector2Array = ring

				if points.size() < 2:
					continue

				draw_polyline(
					points,
					line_color,
					line_width / max(view_scale, 0.25),
					true
				)


func _validate_seats() -> bool:
	var ids := {}

	for seat in seats:
		var unique_id: String = str(
			seat["unique_id"]
		)

		if unique_id.is_empty():
			push_error(
				"Seat has empty unique_id"
			)

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
