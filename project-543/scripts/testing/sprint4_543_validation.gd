extends SceneTree

const GIS_PATH := "res://data/generated/india_ls_seats_543_runtime.geojson"

func _initialize() -> void:
	var loader := GISDataLoader.new()
	var seats: Array = loader.load_seats(GIS_PATH)

	if seats.size() != 543:
		push_error("SPRINT 4 FAILURE: expected 543 GIS seats, got %s" % seats.size())
		quit(1)
		return

	var registry := ConstituencyRegistry.new()
	for seat in seats:
		var unique_id := String(seat.get("unique_id", ""))
		var name := String(seat.get("ls_seat_name", ""))
		var state := String(seat.get("state_ut_name", ""))
		var state_code := String(seat.get("state_ut_code", ""))
		var constituency := Constituency.new(
			unique_id,
			name,
			state,
			state_code,
			unique_id,
			0,
			0.0,
			false,
			null,
			{"source": "existing GIS runtime GeoJSON", "approval_status": "source_identity"}
		)
		if not registry.add(constituency):
			push_error("SPRINT 4 FAILURE: duplicate/invalid constituency ID '%s'" % unique_id)
			quit(1)
			return

	if registry.size() != 543:
		push_error("SPRINT 4 FAILURE: registry size is %s, expected 543" % registry.size())
		quit(1)
		return

	var errors := registry.validate()
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return

	print("SPRINT 4 PASS: 543 GIS constituency identities validated.")
	quit(0)
