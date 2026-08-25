extends Node2D


@onready var map: Node2D = $IndiaMap
@onready var constituency_panel: PanelContainer = $HUD/Panel


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

	map.constituency_selected.connect(
		constituency_panel.show_constituency
	)

	map.constituency_cleared.connect(
		constituency_panel.clear_constituency
	)
