class_name S7EventLog
extends RefCounted

var _events: Array = []


func append(event) -> Dictionary:
	if event == null:
		return {
			"ok": false,
			"code": "INVALID_EVENT"
		}

	var validation: Array = event.validate()

	if not validation.is_empty():
		return {
			"ok": false,
			"code": "INVALID_EVENT",
			"errors": validation
		}

	_events.append(
		S7CampaignEvent.from_dictionary(
			event.to_dictionary()
		)
	)

	return {
		"ok": true,
		"code": "OK"
	}


func size() -> int:
	return _events.size()


func all_events() -> Array:
	var result: Array = []

	for event in _events:
		result.append(
			S7CampaignEvent.from_dictionary(
				event.to_dictionary()
			)
		)

	return result


func events_for_week(week: int) -> Array:
	var result: Array = []

	for event in _events:
		if event.week == week:
			result.append(
				S7CampaignEvent.from_dictionary(
					event.to_dictionary()
				)
			)

	return result


func to_dictionary() -> Dictionary:
	var serialized: Array = []

	for event in _events:
		serialized.append(event.to_dictionary())

	return {
		"events": serialized
	}


static func from_dictionary(data: Dictionary):
	var result = S7EventLog.new()

	for raw in data.get("events", []):
		if raw is Dictionary:
			result._events.append(
				S7CampaignEvent.from_dictionary(raw)
			)

	return result
