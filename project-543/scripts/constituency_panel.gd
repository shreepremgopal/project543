extends PanelContainer


signal poll_requested(tier: int)
signal turn_requested()


var title_label: Label
var state_label: Label
var id_label: Label
var leader_label: Label
var support_label: Label
var opportunity_label: Label
var information_label: Label
var explanation_label: Label

var basic_button: Button
var standard_button: Button
var deep_button: Button
var turn_button: Button


func _ready() -> void:
	custom_minimum_size = Vector2(
		390.0,
		520.0
	)

	_build_ui()


func _build_ui() -> void:
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
		16
	)

	margin.add_theme_constant_override(
		"margin_bottom",
		16
	)

	add_child(margin)

	var box := VBoxContainer.new()

	box.add_theme_constant_override(
		"separation",
		9
	)

	margin.add_child(box)

	title_label = Label.new()
	title_label.text = "POLITICAL INTELLIGENCE"
	title_label.add_theme_font_size_override(
		"font_size",
		24
	)
	box.add_child(title_label)

	state_label = Label.new()
	state_label.text = "State / UT: —"
	box.add_child(state_label)

	id_label = Label.new()
	id_label.text = "Seat ID: —"
	box.add_child(id_label)

	leader_label = Label.new()
	leader_label.text = "Leader: —"
	box.add_child(leader_label)

	support_label = Label.new()
	support_label.text = "Your support: —"
	box.add_child(support_label)

	opportunity_label = Label.new()
	opportunity_label.text = "Opportunity: —"
	box.add_child(opportunity_label)

	information_label = Label.new()
	information_label.text = "Information: No poll"
	box.add_child(information_label)

	var separator := HSeparator.new()
	box.add_child(separator)

	var poll_title := Label.new()
	poll_title.text = "PAID POLLING"
	poll_title.add_theme_font_size_override(
		"font_size",
		16
	)
	box.add_child(poll_title)

	basic_button = Button.new()
	basic_button.text = "Basic Poll  ₹10,000"
	basic_button.pressed.connect(
		func() -> void:
			poll_requested.emit(
				PollingModel.Tier.BASIC
			)
	)
	box.add_child(basic_button)

	standard_button = Button.new()
	standard_button.text = "Standard Poll  ₹25,000"
	standard_button.pressed.connect(
		func() -> void:
			poll_requested.emit(
				PollingModel.Tier.STANDARD
			)
	)
	box.add_child(standard_button)

	deep_button = Button.new()
	deep_button.text = "Deep Poll  ₹50,000"
	deep_button.pressed.connect(
		func() -> void:
			poll_requested.emit(
				PollingModel.Tier.DEEP
			)
	)
	box.add_child(deep_button)

	turn_button = Button.new()
	turn_button.text = "Advance Turn"
	turn_button.pressed.connect(
		func() -> void:
			turn_requested.emit()
	)
	box.add_child(turn_button)

	var info_separator := HSeparator.new()
	box.add_child(info_separator)

	explanation_label = Label.new()
	explanation_label.text = (
		"Select a constituency on the map."
	)
	explanation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(explanation_label)


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


func show_political_intelligence(
	info: Dictionary
) -> void:
	var seat: Dictionary = info.get(
		"seat",
		{}
	)

	var support: Dictionary = info.get(
		"support",
		{}
	)

	title_label.text = str(
		seat.get(
			"ls_seat_name",
			"Unknown constituency"
		)
	)

	state_label.text = (
		"State / UT: "
		+ str(
			seat.get(
				"state_ut_name",
				"Unknown"
			)
		)
	)

	id_label.text = (
		"Seat ID: "
		+ str(
			seat.get(
				"unique_id",
				"Unknown"
			)
		)
	)

	leader_label.text = (
		"Leader: "
		+ str(
			info.get(
				"leader",
				"—"
			)
		)
	)

	var player_support := float(
		info.get(
			"player_support",
			0.0
		)
	)

	support_label.text = (
		"Your support: %.1f%%"
		% (player_support * 100.0)
	)

	var leader_id := str(
		info.get(
			"leader",
			""
		)
	)

	var leader_support := float(
		support.get(
			leader_id,
			0.0
		)
	)

	var margin := (
		leader_support - player_support
	)

	if leader_id == "party_player":
		opportunity_label.text = (
			"Opportunity: DEFEND • %.1f%% lead"
			% (-margin * 100.0)
		)
	elif margin < 0.05:
		opportunity_label.text = (
			"Opportunity: HIGH • marginal contest"
		)
	elif margin < 0.15:
		opportunity_label.text = (
			"Opportunity: MEDIUM • contestable"
		)
	else:
		opportunity_label.text = (
			"Opportunity: LOW • structural gap"
		)

	information_label.text = (
		"Information: No current poll"
	)

	explanation_label.text = str(
		info.get(
			"explanation",
			""
		)
	)


func show_poll_report(
	report: Dictionary
) -> void:
	var tier := str(
		report.get(
			"tier",
			"UNKNOWN"
		)
	)

	var uncertainty := float(
		report.get(
			"uncertainty",
			0.0
		)
	)

	information_label.text = (
		"Poll: %s • ±%.1f%% • CURRENT"
		% [
			tier,
			uncertainty * 100.0
		]
	)

	var results: Dictionary = report.get(
		"results",
		{}
	)

	var player_result: Dictionary = results.get(
		"party_player",
		{}
	)

	if not player_result.is_empty():
		var estimate := float(
			player_result.get(
				"estimate",
				0.0
			)
		)

		var lower := float(
			player_result.get(
				"lower",
				0.0
			)
		)

		var upper := float(
			player_result.get(
				"upper",
				0.0
			)
		)

		support_label.text = (
			"Your poll: %.1f%%  [%.1f–%.1f%%]"
			% [
				estimate * 100.0,
				lower * 100.0,
				upper * 100.0
			]
		)


func mark_information_stale() -> void:
	information_label.text = (
		"Information: STALE • refresh with a poll"
	)


func clear_constituency() -> void:
	title_label.text = (
		"POLITICAL INTELLIGENCE"
	)

	state_label.text = "State / UT: —"
	id_label.text = "Seat ID: —"
	leader_label.text = "Leader: —"
	support_label.text = "Your support: —"
	opportunity_label.text = "Opportunity: —"
	information_label.text = "Information: No poll"

	explanation_label.text = (
		"Select a constituency on the map."
	)
