class_name S7ElectionResult
extends RefCounted

const SCHEMA_VERSION := 1

var schema_version: int = SCHEMA_VERSION
var seat_count: int = 0
var constituency_results: Array = []
var seat_totals: Dictionary = {}
var winner_party_id: String = ""

func validate() -> Array[String]:
	var errors: Array[String] = []
	if schema_version != SCHEMA_VERSION:
		errors.append("unsupported election result schema version")
	if seat_count < 0:
		errors.append("seat_count must be >= 0")
	if constituency_results.size() != seat_count:
		errors.append("constituency result count must equal seat_count")
	if winner_party_id.is_empty() and seat_count > 0:
		errors.append("winner_party_id must not be empty")
	var total_seats := 0
	for party_id in seat_totals:
		var seats := int(seat_totals[party_id])
		if seats < 0:
			errors.append("seat totals must not be negative")
		total_seats += seats
	if total_seats != seat_count:
		errors.append("seat totals must equal seat_count")
	return errors

func is_valid() -> bool:
	return validate().is_empty()

func to_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"seat_count": seat_count,
		"constituency_results": constituency_results.duplicate(true),
		"seat_totals": seat_totals.duplicate(true),
		"winner_party_id": winner_party_id
	}

static func from_dictionary(data: Dictionary) -> S7ElectionResult:
	var result := S7ElectionResult.new()
	result.schema_version = int(data.get("schema_version", SCHEMA_VERSION))
	result.seat_count = int(data.get("seat_count", 0))
	result.constituency_results = data.get("constituency_results", []).duplicate(true)
	result.seat_totals = data.get("seat_totals", {}).duplicate(true)
	result.winner_party_id = str(data.get("winner_party_id", ""))
	return result
