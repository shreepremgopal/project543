extends PanelContainer


var title_label: Label
var state_label: Label
var id_label: Label
var status_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(
		300.0,
		180.0
	)

	var margin := MarginContainer.new()

	margin.add_theme_constant_override(
		"margin_left",
		18
	)

	margin.add_theme_constant_override(
		"margin_right",
		18
	)

	margin.add_theme_constant_override(
		"margin_top",
		14
	)

	margin.add_theme_constant_override(
		"margin_bottom",
		14
	)

	add_child(margin)

	var box := VBoxContainer.new()

	box.add_theme_constant_override(
		"separation",
		8
	)

	margin.add_child(box)

	title_label = Label.new()
	title_label.text = "No constituency selected"
	title_label.add_theme_font_size_override(
		"font_size",
		22
	)
	box.add_child(title_label)

	state_label = Label.new()
	state_label.text = "State / UT: —"
	box.add_child(state_label)

	id_label = Label.new()
	id_label.text = "Seat ID: —"
	box.add_child(id_label)

	status_label = Label.new()
	status_label.text = "Click a constituency"
	box.add_child(status_label)


func show_constituency(
	seat: Dictionary
) -> void:
	var seat_name := str(
		seat.get(
			"ls_seat_name",
			"Unknown constituency"
		)
	)

	var state_name := str(
		seat.get(
			"state_ut_name",
			"Unknown State / UT"
		)
	)

	var unique_id := str(
		seat.get(
			"unique_id",
			"Unknown"
		)
	)

	title_label.text = seat_name
	state_label.text = (
		"State / UT: "
		+ state_name
	)

	id_label.text = (
		"Seat ID: "
		+ unique_id
	)

	status_label.text = (
		"Constituency selected"
	)


func clear_constituency() -> void:
	title_label.text = (
		"No constituency selected"
	)

	state_label.text = (
		"State / UT: —"
	)

	id_label.text = (
		"Seat ID: —"
	)

	status_label.text = (
		"Click a constituency"
	)
