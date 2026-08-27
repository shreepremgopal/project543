extends Node2D


@onready var map: Node2D = $IndiaMap
@onready var constituency_panel: PanelContainer = $HUD/Panel


var political_system: PoliticalSystem


func _ready() -> void:
	print("MAIN CHILDREN: ", get_children())

	print("IndiaMap node: ", get_node_or_null("IndiaMap"))
	print("Panel node: ", get_node_or_null("HUD/Panel"))

	if map == null:
		push_error(
			"MAIN ERROR: IndiaMap was not found under Main."
		)
		return

	if constituency_panel == null:
		push_error(
			"MAIN ERROR: HUD/Panel was not found."
		)
		return

	political_system = PoliticalSystem.new()

	map.constituency_selected.connect(
		_on_constituency_selected
	)

	map.constituency_cleared.connect(
		constituency_panel.clear_constituency
	)


func _on_constituency_selected(
	constituency_id: String
) -> void:
	constituency_panel.show_constituency(
		constituency_id
	)

	var party_id := PoliticalMapAdapter.leading_party_id(
		political_system.state,
		constituency_id
	)

	var colour := PoliticalMapAdapter.leading_party_colour(
		political_system.state,
		political_system.party_registry,
		constituency_id
	)

	print(
		"Selected constituency: ",
		constituency_id,
		" | Leading party: ",
		party_id,
		" | Colour: ",
		colour
	)