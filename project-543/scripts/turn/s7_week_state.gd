class_name S7WeekState
extends RefCounted

var week_number: int = 1
var actions_allowed: int = 2
var actions_used: int = 0
var actions_remaining: int = 2
var resolved: bool = false
var resolution_id: String = ""


func _init(
	week: int = 1,
	allowed: int = 2
) -> void:
	reset(week, allowed)


func reset(
	week: int,
	allowed: int
) -> void:
	week_number = week
	actions_allowed = allowed
	actions_used = 0
	actions_remaining = allowed
	resolved = false
	resolution_id = ""


func can_commit_action() -> bool:
	return not resolved and actions_remaining > 0


func commit_action() -> bool:
	if not can_commit_action():
		return false

	actions_used += 1
	actions_remaining -= 1

	return true


func mark_resolved(id: String) -> bool:
	if resolved:
		return false

	resolved = true
	resolution_id = id

	return true


func validate() -> Array:
	var errors: Array = []

	if week_number < 1:
		errors.append("week_number must be >= 1")

	if actions_allowed < 0:
		errors.append("actions_allowed must be >= 0")

	if actions_used < 0:
		errors.append("actions_used must be >= 0")

	if actions_used > actions_allowed:
		errors.append("actions_used exceeds actions_allowed")

	if actions_remaining < 0:
		errors.append("actions_remaining must be >= 0")

	if actions_remaining != actions_allowed - actions_used:
		errors.append("actions_remaining invariant violated")

	if resolved and resolution_id.is_empty():
		errors.append("resolved week requires resolution_id")

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func to_dictionary() -> Dictionary:
	return {
		"week_number": week_number,
		"actions_allowed": actions_allowed,
		"actions_used": actions_used,
		"actions_remaining": actions_remaining,
		"resolved": resolved,
		"resolution_id": resolution_id
	}


static func from_dictionary(data: Dictionary):
	var result = S7WeekState.new(
		int(data.get("week_number", 1)),
		int(data.get("actions_allowed", 2))
	)

	result.actions_used = int(data.get("actions_used", 0))
	result.actions_remaining = int(
		data.get(
			"actions_remaining",
			result.actions_allowed - result.actions_used
		)
	)
	result.resolved = bool(data.get("resolved", false))
	result.resolution_id = str(data.get("resolution_id", ""))

	return result
