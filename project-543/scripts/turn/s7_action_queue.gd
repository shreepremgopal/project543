class_name S7ActionQueue
extends RefCounted

var _actions: Array = []


func clear() -> void:
	_actions.clear()


func size() -> int:
	return _actions.size()


func is_empty() -> bool:
	return _actions.is_empty()


func contains_action(action_id: String) -> bool:
	for action in _actions:
		if action.action_id == action_id:
			return true

	return false


func commit(action) -> Dictionary:
	if action == null:
		return {
			"ok": false,
			"code": "INVALID_ACTION",
			"errors": ["action is null"]
		}

	var validation: Array = action.validate()

	if not validation.is_empty():
		return {
			"ok": false,
			"code": "INVALID_ACTION",
			"errors": validation
		}

	if contains_action(action.action_id):
		return {
			"ok": false,
			"code": "DUPLICATE_ACTION",
			"errors": ["action_id already exists"]
		}

	var committed = action.snapshot()
	committed.commit()

	_actions.append(committed)

	_sort_actions()

	return {
		"ok": true,
		"code": "OK",
		"action": committed
	}


func get_week_actions(week: int) -> Array:
	var result: Array = []

	for action in _actions:
		if action.turn == week:
			result.append(action)

	return result


func remove_week_actions(week: int) -> void:
	var remaining: Array = []

	for action in _actions:
		if action.turn != week:
			remaining.append(action)

	_actions = remaining


func all_actions() -> Array:
	var result: Array = []

	for action in _actions:
		result.append(action.snapshot())

	return result


func _sort_actions() -> void:
	_actions.sort_custom(
		func(a, b):
			if a.turn == b.turn:
				return a.sequence < b.sequence

			return a.turn < b.turn
	)


func to_dictionary() -> Dictionary:
	var serialized: Array = []

	for action in _actions:
		serialized.append(action.to_dictionary())

	return {
		"actions": serialized
	}


static func from_dictionary(data: Dictionary):
	var result = S7ActionQueue.new()

	for raw in data.get("actions", []):
		if raw is Dictionary:
			result._actions.append(
				S7ActionCommitment.from_dictionary(raw)
			)

	result._sort_actions()

	return result
