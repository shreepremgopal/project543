class_name PoliticalInformationState
extends RefCounted


var current_turn: int = 1
var reports: Dictionary = {}


func advance_turn(
	new_turn: int
) -> bool:
	if new_turn < current_turn:
		return false

	current_turn = new_turn
	return true


func store_report(
	report: Dictionary
) -> bool:
	var constituency_id := String(
		report.get("constituency_id", "")
	)

	if constituency_id.is_empty():
		return false

	reports[constituency_id] = (
		report.duplicate(true)
	)

	return true


func has_report(
	constituency_id: String
) -> bool:
	return reports.has(constituency_id)


func get_report(
	constituency_id: String
) -> Dictionary:
	if not reports.has(constituency_id):
		return {}

	return reports[
		constituency_id
	].duplicate(true)


func is_stale(
	constituency_id: String,
	stale_after_turns: int
) -> bool:
	if not reports.has(constituency_id):
		return true

	var report: Dictionary = reports[
		constituency_id
	]

	var report_turn := int(
		report.get("turn", -1)
	)

	if report_turn < 0:
		return true

	return (
		current_turn - report_turn
		>= stale_after_turns
	)


func to_dictionary() -> Dictionary:
	var serialized := {}

	var ids: Array[String] = []

	for key in reports.keys():
		ids.append(String(key))

	ids.sort()

	for constituency_id in ids:
		serialized[constituency_id] = (
			reports[constituency_id]
		)

	return {
		"current_turn": current_turn,
		"reports": serialized
	}


static func from_dictionary(
	data: Dictionary
) -> PoliticalInformationState:
	var state := PoliticalInformationState.new()

	state.current_turn = int(
		data.get("current_turn", 1)
	)

	var reports_data = data.get(
		"reports",
		{}
	)

	if typeof(reports_data) == TYPE_DICTIONARY:
		for key in reports_data.keys():
			state.reports[String(key)] = (
				reports_data[key].duplicate(true)
			)

	return state
