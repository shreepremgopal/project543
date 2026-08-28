extends Node2D


const PERSONA_PATH := "res://data/political/political_personas_v0_1.json"
const POLITICAL_CONFIG_PATH := "res://data/political/political_balance_v0_1.json"
const GAME_SEED := 543051

@onready var map: Node2D = $IndiaMap
@onready var panel: PanelContainer = $HUD/Panel

var status_label: Label
var money_label: Label
var turn_label: Label

var political_system: PoliticalSystem
var selected_seat: Dictionary = {}
var selected_constituency_id := ""
var player_party_id := "party_player"


func _ready() -> void:
	status_label = _find_label("Status")
	money_label = _find_label("Money")
	turn_label = _find_label("Turn")

	if map == null:
		push_error("MAIN: IndiaMap is missing.")
		return

	if panel == null:
		push_error("MAIN: HUD/Panel is missing.")
		return

	if status_label == null:
		push_error("MAIN: Status label is missing.")

	if money_label == null:
		push_error("MAIN: Money label is missing.")

	if turn_label == null:
		push_error("MAIN: Turn label is missing.")

	if not map.constituency_selected.is_connected(
		_on_constituency_selected
	):
		map.constituency_selected.connect(
			_on_constituency_selected
		)

	if not map.constituency_hovered.is_connected(
		_on_constituency_hovered
	):
		map.constituency_hovered.connect(
			_on_constituency_hovered
		)

	if not map.constituency_cleared.is_connected(
		_on_constituency_cleared
	):
		map.constituency_cleared.connect(
			_on_constituency_cleared
		)

	_initialize_political_game()


func _find_label(label_name: String) -> Label:
	var node := find_child(
		label_name,
		true,
		false
	)

	if node is Label:
		return node as Label

	return null


func _set_status(value: String) -> void:
	if status_label != null:
		status_label.text = value


func _set_money(value: String) -> void:
	if money_label != null:
		money_label.text = value


func _set_turn(value: String) -> void:
	if turn_label != null:
		turn_label.text = value


func _initialize_political_game() -> void:
	_set_status(
		"INITIALISING POLITICAL INTELLIGENCE..."
	)

	var config := PoliticalBalanceConfig.load_json(
		POLITICAL_CONFIG_PATH
	)

	if not config.is_valid():
		push_error(
			"MAIN: Political configuration is invalid."
		)
		_set_status(
			"POLITICAL CONFIGURATION ERROR"
		)
		return

	political_system = PoliticalSystem.new(
		config
	)

	var personas := PersonaCatalogLoader.load_exact_25(
		PERSONA_PATH
	)

	if personas == null:
		push_error(
			"MAIN: Persona catalogue failed to load."
		)
		_set_status(
			"PERSONA DATA ERROR"
		)
		return

	if personas.size() != 25:
		push_error(
			"MAIN: Expected 25 personas, got %d."
			% personas.size()
		)
		_set_status(
			"PERSONA DATA ERROR"
		)
		return

	political_system.persona_registry = personas

	_create_parties()
	_create_constituencies()

	_set_status(
		"CALCULATING POLITICAL LANDSCAPE..."
	)

	var results := political_system.calculate_all_bound()

	if results.size() != map.seats.size():
		push_error(
			"MAIN: Political calculation mismatch. "
			+ "Expected %d, got %d."
			% [
				map.seats.size(),
				results.size()
			]
		)

	if map.has_method("bind_political_state"):
		map.bind_political_state(
			political_system.state,
			political_system.party_registry
		)

	_update_top_bar()

	_set_status(
		"POLITICAL INTELLIGENCE ONLINE • %d CONSTITUENCIES"
		% results.size()
	)


func _create_parties() -> void:
	var definitions := [
		[
			"party_player",
			"National Reform",
			"#3B82F6",
			-0.15,
			0.20,
			-0.10,
			0.30,
			0.20,
			0.25
		],
		[
			"party_alpha",
			"Development Front",
			"#F97316",
			0.35,
			-0.05,
			0.20,
			0.05,
			-0.15,
			0.35
		],
		[
			"party_beta",
			"People's Coalition",
			"#22C55E",
			-0.25,
			0.40,
			0.10,
			-0.05,
			0.30,
			-0.05
		],
		[
			"party_gamma",
			"Civic Alliance",
			"#A855F7",
			0.05,
			0.10,
			-0.25,
			0.40,
			0.05,
			0.00
		]
	]

	for item in definitions:
		var party_id: String = item[0]
		var party_name: String = item[1]
		var colour: String = item[2]

		var ideology := IdeologyProfile.new(
			float(item[3]),
			float(item[4]),
			float(item[5]),
			float(item[6]),
			float(item[7]),
			float(item[8])
		)

		var definition := PartyDefinition.new(
			party_id,
			party_name,
			colour,
			"National Campaign Leader",
			ideology,
			{
				"source": "Project 543 Sprint 5"
			}
		)

		var base_support := {}

		for seat in map.seats:
			var constituency_id := str(
				seat.get("unique_id", "")
			)

			if constituency_id.is_empty():
				continue

			base_support[constituency_id] = (
				_base_support(
					constituency_id,
					party_id
				)
			)

		var state := PartyState.new(
			party_id,
			1000000,
			100000,
			0.25,
			"",
			base_support
		)

		political_system.party_registry.add(
			definition,
			state
		)


func _create_constituencies() -> void:
	for seat in map.seats:
		var constituency_id := str(
			seat.get("unique_id", "")
		)

		if constituency_id.is_empty():
			continue

		var distribution := PersonaDistribution.new()
		var persona_ids := political_system.persona_registry.ids()

		for persona_id in persona_ids:
			var key := "%s|%s|%s" % [
				GAME_SEED,
				constituency_id,
				persona_id
			]

			var digest := key.sha256_text()
			var weight := (
				_hex_value(
					digest.substr(0, 6)
				) % 1000
			) + 1

			distribution.set_share(
				persona_id,
				weight
			)

		var constituency := Constituency.new(
			constituency_id,
			str(
				seat.get(
					"ls_seat_name",
					constituency_id
				)
			),
			str(
				seat.get(
					"state_ut_name",
					"Unknown"
				)
			),
			str(
				seat.get(
					"state_ut_name",
					"UNK"
				)
			),
			constituency_id,
			1000000,
			0.50,
			true,
			distribution,
			{
				"source": "Project 543 GIS dataset"
			}
		)

		political_system.constituency_registry.add(
			constituency
		)


func _base_support(
	constituency_id: String,
	party_id: String
) -> float:
	var key := "%s|%s|base" % [
		constituency_id,
		party_id
	]

	var digest := key.sha256_text()
	var raw := _hex_value(
		digest.substr(0, 8)
	)

	return 0.15 + float(
		raw % 4500
	) / 10000.0


func _hex_value(value: String) -> int:
	var result := 0

	for character in value.to_lower():
		var digit := (
			"0123456789abcdef".find(character)
		)

		if digit >= 0:
			result = result * 16 + digit

	return result


func _on_constituency_selected(
	seat: Dictionary
) -> void:
	selected_seat = seat.duplicate(true)

	selected_constituency_id = str(
		seat.get(
			"unique_id",
			""
		)
	)

	_refresh_panel()


func _on_constituency_hovered(
	seat: Dictionary
) -> void:
	if selected_constituency_id.is_empty():
		_set_status(
			"HOVER • %s"
			% str(
				seat.get(
					"ls_seat_name",
					"Constituency"
				)
			)
		)


func _on_constituency_cleared() -> void:
	selected_seat.clear()
	selected_constituency_id = ""

	if panel != null and panel.has_method(
		"clear_constituency"
	):
		panel.clear_constituency()

	_set_status(
		"SELECT A CONSTITUENCY"
	)


func _refresh_panel() -> void:
	if political_system == null:
		return

	if selected_constituency_id.is_empty():
		return

	var constituency := (
		political_system.constituency_registry
		.get_constituency(
			selected_constituency_id
		)
	)

	if constituency == null:
		return

	var support := (
		political_system.state.get_support(
			selected_constituency_id
		)
	)

	var leader := (
		political_system.state
		.get_leading_party_id(
			selected_constituency_id
		)
	)

	var player_support := float(
		support.get(
			player_party_id,
			0.0
		)
	)

	var info := {
		"seat": selected_seat,
		"constituency": constituency,
		"support": support,
		"leader": leader,
		"player_support": player_support,
		"turn": political_system.state.turn,
		"explanation": _explanation(
			leader,
			player_support,
			float(
				support.get(
					leader,
					0.0
				)
			)
		)
	}

	if panel.has_method(
		"show_political_intelligence"
	):
		panel.show_political_intelligence(info)
	elif panel.has_method(
		"show_constituency"
	):
		panel.show_constituency(
			selected_seat
	)


func _explanation(
	leader: String,
	player_support: float,
	leader_support: float
) -> String:
	if leader == player_party_id:
		return (
			"Your party leads. Protect this constituency."
		)

	var margin := (
		leader_support - player_support
	)

	if margin < 0.05:
		return "Highly competitive constituency."

	if margin < 0.15:
		return "Contestable constituency."

	return (
		"Large structural gap. "
		+ "Gather information first."
	)


func _update_top_bar() -> void:
	if political_system == null:
		return

	var state := (
		political_system.party_registry
		.get_state(
			player_party_id
		)
	)

	if state != null:
		_set_money(
			"FUNDS  ₹%s"
			% _money(state.money)
		)

	_set_turn(
		"TURN  %02d"
		% political_system.state.turn
	)


func _money(value: int) -> String:
	var text := str(value)
	var output := ""
	var count := 0

	for index in range(
		text.length() - 1,
		-1,
		-1
	):
		output = text[index] + output
		count += 1

		if count == 3 and index > 0:
			output = "," + output
			count = 0

	return output
