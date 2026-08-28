extends RefCounted

const ResolverScript = preload("res://scripts/election/s7_election_resolver.gd")

var passed := 0
var failed := 0

func run_all() -> void:
	passed = 0
	failed = 0
	_test_single_seat()
	_test_543_seats()
	_test_deterministic_tie_break()
	_test_campaign_modifier()
	_test_invalid_input()
	print("S7 ELECTION RESOLVER: %d passed, %d failed" % [passed, failed])

func _test_single_seat() -> void:
	var resolver = ResolverScript.new()
	var result = resolver.resolve(
		[
			{"party_id": "A", "ideology": {"economic": 1.0}},
			{"party_id": "B", "ideology": {"economic": -1.0}}
		],
		[
			{"constituency_id": "C1", "personas": [{"weight": 1.0, "ideology": {"economic": 1.0}}], "base_support": {"A": 0.0, "B": 0.0}}
		]
	)
	_assert(result.ok, "single constituency resolves")
	_assert(result.seat_count == 1, "single constituency produces one seat")
	_assert(result.winner_party_id == "A", "aligned party wins")

func _test_543_seats() -> void:
	var resolver = ResolverScript.new()
	var constituencies: Array = []
	for i in range(543):
		constituencies.append({
			"constituency_id": "C%03d" % (i + 1),
			"personas": [],
			"base_support": {"A": 1.0, "B": 0.0}
		})
	var result = resolver.resolve(
		[{"party_id": "A", "ideology": {}}, {"party_id": "B", "ideology": {}}],
		constituencies
	)
	_assert(result.ok, "543 constituencies resolve")
	_assert(result.seat_count == 543, "exactly 543 seats are resolved")
	_assert(int(result.seat_totals["A"]) == 543, "all 543 seats go to highest scorer")

func _test_deterministic_tie_break() -> void:
	var resolver = ResolverScript.new()
	var result = resolver.resolve(
		[{"party_id": "A", "ideology": {}}, {"party_id": "B", "ideology": {}}],
		[{"constituency_id": "C1", "personas": [], "base_support": {"A": 1.0, "B": 1.0}}]
	)
	_assert(result.winner_party_id == "A", "party order provides stable tie break")

func _test_campaign_modifier() -> void:
	var resolver = ResolverScript.new()
	var result = resolver.resolve(
		[{"party_id": "A", "ideology": {}}, {"party_id": "B", "ideology": {}}],
		[{"constituency_id": "C1", "personas": [], "base_support": {"A": 1.0, "B": 1.1}}],
		{"constituencies": {"C1": {"support_delta": {"A": 0.2}}}}
	)
	_assert(result.winner_party_id == "A", "campaign constituency modifier can flip a seat")

func _test_invalid_input() -> void:
	var resolver = ResolverScript.new()
	var result = resolver.resolve([], [])
	_assert(not result.ok, "empty election input rejected")
	_assert(result.code == "NO_PARTIES", "empty election has deterministic error code")

func _assert(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		print("FAIL: %s" % label)
