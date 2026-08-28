class_name S7ElectionResult
extends RefCounted

const SCHEMA_VERSION := 2

var schema_version: int = SCHEMA_VERSION
var model_version: String = "election-v0.1"
var seed: int = 0
var seat_count: int = 0
var constituency_results: Array = []
var seat_totals: Dictionary = {}
var vote_totals: Dictionary = {}
var national_vote_shares: Dictionary = {}
var winner_party_id: String = ""


func validate() -> Array[String]:
	var errors: Array[String] = []
	if schema_version != SCHEMA_VERSION and schema_version != 1:
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

	var seen_constituencies := {}
	var derived_seats := {}
	var derived_votes := {}
	for index in constituency_results.size():
		var item = constituency_results[index]
		if not item is Dictionary:
			errors.append("constituency result %d is not a Dictionary" % index)
			continue
		var seat_result: Dictionary = item
		var constituency_id := String(seat_result.get("constituency_id", ""))
		if constituency_id.is_empty():
			errors.append("constituency result %d has no constituency_id" % index)
		elif seen_constituencies.has(constituency_id):
			errors.append("duplicate constituency result: %s" % constituency_id)
		else:
			seen_constituencies[constituency_id] = true

		var winner := String(seat_result.get("winner_party_id", ""))
		var raw_votes = seat_result.get("votes", {})
		if not raw_votes is Dictionary:
			errors.append("votes for constituency %s are not a Dictionary" % constituency_id)
			continue
		var votes: Dictionary = raw_votes
		var declared_total := int(seat_result.get("total_votes", -1))
		var calculated_total := 0
		var highest_votes := -1
		var highest_party := ""
		for party_id in votes.keys():
			var party_votes := int(votes[party_id])
			if party_votes < 0:
				errors.append("negative votes in constituency %s" % constituency_id)
			calculated_total += party_votes
			if party_votes > highest_votes:
				highest_votes = party_votes
				highest_party = String(party_id)
			derived_votes[party_id] = int(derived_votes.get(party_id, 0)) + party_votes
		if declared_total <= 0:
			errors.append("constituency %s has no positive vote total" % constituency_id)
		elif calculated_total != declared_total:
			errors.append("votes do not conserve in constituency %s" % constituency_id)
		if winner.is_empty() or winner != highest_party:
			errors.append("winner is not the highest-vote party in constituency %s" % constituency_id)
		derived_seats[winner] = int(derived_seats.get(winner, 0)) + 1

	for party_id in seat_totals.keys():
		if int(seat_totals[party_id]) != int(derived_seats.get(party_id, 0)):
			errors.append("seat total mismatch for party %s" % party_id)
	for party_id in derived_seats.keys():
		if not seat_totals.has(party_id):
			errors.append("winner party %s is missing from seat_totals" % party_id)

	for party_id in vote_totals:
		var total_votes_for_party := int(vote_totals[party_id])
		if total_votes_for_party < 0:
			errors.append("vote totals must not be negative")
		if total_votes_for_party != int(derived_votes.get(party_id, 0)):
			errors.append("vote total mismatch for party %s" % party_id)
	for party_id in derived_votes.keys():
		if not vote_totals.has(party_id):
			errors.append("vote party %s is missing from vote_totals" % party_id)

	if not national_vote_shares.is_empty():
		var share_total := 0.0
		for party_id in national_vote_shares:
			var share := float(national_vote_shares[party_id])
			if not is_finite(share) or share < 0.0 or share > 1.0:
				errors.append("invalid national vote share for party %s" % party_id)
			share_total += share
		if seat_count > 0 and not is_equal_approx(share_total, 1.0):
			errors.append("national vote shares must sum to one")
	return errors


func is_valid() -> bool:
	return validate().is_empty()


func to_dictionary() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"model_version": model_version,
		"seed": seed,
		"seat_count": seat_count,
		"constituency_results": constituency_results.duplicate(true),
		"seat_totals": seat_totals.duplicate(true),
		"vote_totals": vote_totals.duplicate(true),
		"national_vote_shares": national_vote_shares.duplicate(true),
		"winner_party_id": winner_party_id
	}


static func from_dictionary(data: Dictionary) -> S7ElectionResult:
	var result := S7ElectionResult.new()
	result.schema_version = int(data.get("schema_version", SCHEMA_VERSION))
	result.model_version = String(data.get("model_version", "election-v0.1"))
	result.seed = int(data.get("seed", 0))
	result.seat_count = int(data.get("seat_count", 0))
	var raw_constituency_results = data.get("constituency_results", [])
	var raw_seat_totals = data.get("seat_totals", {})
	var raw_vote_totals = data.get("vote_totals", {})
	var raw_national_shares = data.get("national_vote_shares", {})
	if raw_constituency_results is Array:
		result.constituency_results = raw_constituency_results.duplicate(true)
	if raw_seat_totals is Dictionary:
		result.seat_totals = raw_seat_totals.duplicate(true)
	if raw_vote_totals is Dictionary:
		result.vote_totals = raw_vote_totals.duplicate(true)
	if raw_national_shares is Dictionary:
		result.national_vote_shares = raw_national_shares.duplicate(true)
	result.winner_party_id = str(data.get("winner_party_id", ""))
	return result
