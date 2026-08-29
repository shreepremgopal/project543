extends SceneTree

const GIS_PATH := "res://data/generated/india_ls_seats_543_runtime.geojson"

var failures: Array[String] = []


func _initialize() -> void:
	_test_election_invariants()
	_test_campaign_start_and_actions()
	_test_save_load_round_trip()
	_test_full_campaign_completion()
	if failures.is_empty():
		print("CAMPAIGN INTEGRATION PASS: election and campaign slice validated.")
		quit(0)
		return
	for failure in failures:
		push_error("CAMPAIGN INTEGRATION FAILURE: " + failure)
	quit(1)


func _test_election_invariants() -> void:
	var seats := GISDataLoader.new().load_seats(GIS_PATH)
	var campaign := CampaignCoordinator.new(seats, 543051)
	var start := campaign.start_new_campaign("party_player", "Test Reform")
	_check(bool(start.get("ok", false)), "campaign world starts")
	var home_id := String(seats[0].get("unique_id", ""))
	var home := campaign.confirm_home(home_id)
	_check(bool(home.get("ok", false)), "home constituency confirms")
	var projection := campaign.get_projection()
	_check(projection != null, "projection exists")
	if projection == null:
		return
	_check(projection.seat_count == 543, "projection resolves all 543 seats")
	_check(projection.is_valid(), "projection passes election result validation")
	var total_seats := 0
	for value in projection.seat_totals.values():
		total_seats += int(value)
	_check(total_seats == 543, "seat totals award exactly 543 seats")
	var total_votes := 0
	for value in projection.vote_totals.values():
		total_votes += int(value)
	for seat_result in projection.constituency_results:
		var seat_votes := 0
		for value in seat_result.get("votes", {}).values():
			seat_votes += int(value)
		_check(seat_votes == int(seat_result.get("total_votes", 0)), "largest-remainder vote allocation conserves votes")
	_check(total_votes > 0, "national vote totals are populated")

	var repeat := ElectionEngine.resolve(
		campaign.constituencies,
		campaign.parties,
		campaign.personas,
		campaign.political_config,
		campaign._campaign_state_snapshot(),
		campaign.turn,
		float(campaign.config.get_value("eligibility_factor", 0.65))
	)
	_check(repeat.to_dictionary() == projection.to_dictionary(), "identical election inputs are deterministic")


func _test_campaign_start_and_actions() -> void:
	var seats := GISDataLoader.new().load_seats(GIS_PATH)
	var campaign := CampaignCoordinator.new(seats, 543051)
	campaign.start_new_campaign("party_player", "Action Test")
	var home_id := String(seats[0].get("unique_id", ""))
	campaign.confirm_home(home_id)
	var before_poll_money := int(campaign.get_summary().get("money", 0))
	var poll := campaign.conduct_poll(home_id, int(PollingModel.Tier.BASIC))
	_check(bool(poll.get("ok", false)), "basic poll commits")
	_check(int(campaign.get_summary().get("money", 0)) == before_poll_money - 10000, "poll uses the audited money ledger")
	var before_money := int(campaign.get_summary().get("money", 0))
	var rally := campaign.execute_player_action("rally", home_id)
	_check(bool(rally.get("ok", false)), "rally commits")
	_check(int(campaign.get_summary().get("money", 0)) == before_money - 100000, "rally uses configured cost")
	var second := campaign.execute_player_action("interview", home_id)
	_check(bool(second.get("ok", false)), "interview commits")
	var third := campaign.execute_player_action("rally", home_id)
	_check(not bool(third.get("ok", false)), "third action is rejected by two-action limit")
	var week := campaign.resolve_week()
	_check(bool(week.get("ok", false)), "week resolves after committed actions")
	_check(campaign.turn == 2, "campaign advances to week two")
	_check(campaign.get_summary().get("actions_remaining", 0) == 2, "new week restores two actions")


func _test_save_load_round_trip() -> void:
	var seats := GISDataLoader.new().load_seats(GIS_PATH)
	var campaign := CampaignCoordinator.new(seats, 543051)
	campaign.start_new_campaign("party_development", "Round Trip Party")
	var home_id := String(seats[12].get("unique_id", ""))
	campaign.confirm_home(home_id)
	campaign.execute_player_action("rally", home_id)
	var saved := campaign.to_dictionary()
	var restored := CampaignCoordinator.from_dictionary(seats, saved)
	_check(restored != null, "valid campaign save restores")
	if restored == null:
		return
	_check(restored.get_summary() == campaign.get_summary(), "save/load preserves campaign summary")
	_check(restored.get_projection().to_dictionary() == campaign.get_projection().to_dictionary(), "save/load preserves deterministic projection")
	var invalid := saved.duplicate(true)
	invalid["schema_version"] = 999
	_check(CampaignCoordinator.from_dictionary(seats, invalid) == null, "incompatible save is rejected safely")


func _test_full_campaign_completion() -> void:
	var seats := GISDataLoader.new().load_seats(GIS_PATH)
	var campaign := CampaignCoordinator.new(seats, 901543)
	campaign.start_new_campaign("party_player", "Completion Party")
	campaign.confirm_home(String(seats[0].get("unique_id", "")))
	for week in range(45):
		var result := campaign.resolve_week()
		_check(bool(result.get("ok", false)), "week %d resolves" % (week + 1))
		if not bool(result.get("ok", false)):
			return
	var election := campaign.get_election_result()
	_check(campaign.phase == CampaignCoordinator.ELECTION_READY, "week 45 enters election-ready phase")
	_check(election != null and election.seat_count == 543, "full campaign resolves all 543 seats")
	_check(election != null and election.is_valid(), "full campaign election result is valid")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
