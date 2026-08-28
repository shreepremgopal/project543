extends SceneTree

var failures: Array[String] = []
var warnings: Array[String] = []
var checked_scripts := 0

func _init() -> void:
	_validate_project_metadata()
	_validate_required_assets()
	_validate_all_gd_scripts("res://scripts")
	_validate_all_gd_scripts("res://tests")
	_validate_all_gd_scripts("res://tools")
	_validate_core_contracts()
	_print_report()
	quit(1 if not failures.is_empty() else 0)

func _validate_project_metadata() -> void:
	var config := ConfigFile.new()
	if config.load("res://project.godot") != OK:
		_fail("project.godot cannot be loaded")
		return
	var run_main := str(config.get_value("application", "run/main_scene", ""))
	if run_main.is_empty():
		_fail("application/run/main_scene is missing")
	elif not FileAccess.file_exists(run_main):
		_fail("main scene does not exist: %s" % run_main)

func _validate_required_assets() -> void:
	var required := [
		"res://Scenes/main.tscn",
		"res://Scenes/india_map.tscn",
		"res://data/generated/india_ls_seats_543_runtime.geojson",
		"res://scripts/turn/s7_turn_engine.gd",
		"res://scripts/turn/s7_resolution_pipeline.gd",
		"res://scripts/turn/s7_action_commitment.gd",
		"res://scripts/turn/election_ready_state.gd"
	]
	for path in required:
		if not FileAccess.file_exists(path):
			_fail("required project asset missing: %s" % path)

func _validate_all_gd_scripts(root: String) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	_validate_dir(root, dir)

func _validate_dir(root: String, dir: DirAccess) -> void:
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name == "." or name == "..":
			continue
		var path := root.path_join(name)
		if dir.current_is_dir():
			var child := DirAccess.open(path)
			if child != null:
				_validate_dir(path, child)
		elif name.ends_with(".gd"):
			checked_scripts += 1
			var script = load(path)
			if script == null:
				_fail("GDScript failed to load/parse: %s" % path)
	dir.list_dir_end()

func _validate_core_contracts() -> void:
	var action_script = load("res://scripts/turn/s7_action_commitment.gd")
	if action_script == null:
		return
	var action = action_script.new("smoke", "PLAYER", "NATIONAL", {}, 1, 1, 0)
	if not action.is_valid():
		_fail("S7ActionCommitment baseline contract is invalid")
	else:
		var snapshot = action.snapshot()
		if snapshot.to_dictionary().get("action_id", "") != "smoke":
			_fail("action snapshot round-trip failed")

	var geojson := FileAccess.open("res://data/generated/india_ls_seats_543_runtime.geojson", FileAccess.READ)
	if geojson != null:
		var text := geojson.get_as_text()
		if text.length() < 100:
			_fail("543-seat GeoJSON appears empty or truncated")
		if not text.contains("FeatureCollection"):
			warnings.append("543-seat GeoJSON does not expose a FeatureCollection marker; runtime loader must validate its schema")

func _fail(message: String) -> void:
	failures.append(message)

func _print_report() -> void:
	print("PROJECT 543 MASTER VALIDATION")
	print("Scripts checked: %d" % checked_scripts)
	print("Warnings: %d" % warnings.size())
	for warning in warnings:
		print("WARNING: %s" % warning)
	print("Failures: %d" % failures.size())
	for failure in failures:
		print("FAIL: %s" % failure)
	if failures.is_empty():
		print("MASTER VALIDATION: PASS")
	else:
		print("MASTER VALIDATION: FAIL")
