extends Node2D

## Project 543's presentation boundary.
## All strategic state is owned by CampaignCoordinator; this script translates
## it into a readable command interface and forwards player intent.

const CampaignCoordinatorScript = preload("res://scripts/campaign/campaign_coordinator.gd")
const PollingModelScript = preload("res://scripts/domain/polling_model.gd")
const SAVE_PATH := "user://project543_campaign.json"

@onready var map: IndiaMap = $IndiaMap

var coordinator: CampaignCoordinator
var selected_id := ""
var pending_home_id := ""
var selected_preset := "party_player"
var tutorial_shown := false

var ui_layer: CanvasLayer
var ui_root: Control
var top_bar: PanelContainer
var command_panel: PanelContainer
var feed_panel: PanelContainer
var setup_overlay: PanelContainer
var home_overlay: PanelContainer
var results_overlay: PanelContainer

var status_label: Label
var phase_label: Label
var week_label: Label
var funds_label: Label
var followers_label: Label
var risk_label: Label
var seats_label: Label

var target_title: Label
var target_meta: Label
var target_support: Label
var target_leader: Label
var target_status: Label
var target_margin: Label
var target_explanation: Label
var poll_status: Label
var manifesto_status: Label
var business_status: Label
var action_status: Label
var feed_label: RichTextLabel

var rally_button: Button
var interview_button: Button
var manifesto_button: Button
var fundraise_buttons: Array[Button] = []
var business_button: Button
var manifesto_select: OptionButton
var business_select: OptionButton
var end_week_button: Button
var save_button: Button
var load_button: Button
var poll_buttons: Array[Button] = []

var party_choice_buttons: Dictionary = {}
var party_name_edit: LineEdit
var home_candidate_label: Label
var confirm_home_button: Button


func _ready() -> void:
	if map == null:
		push_error("MAIN: IndiaMap scene is missing")
		return
	if not map.constituency_selected.is_connected(_on_constituency_selected):
		map.constituency_selected.connect(_on_constituency_selected)
	if not map.constituency_hovered.is_connected(_on_constituency_hovered):
		map.constituency_hovered.connect(_on_constituency_hovered)
	if not map.constituency_cleared.is_connected(_on_constituency_cleared):
		map.constituency_cleared.connect(_on_constituency_cleared)
	call_deferred("_boot")


func _boot() -> void:
	if map.seats.size() != 543:
		_show_boot_error("MAP DATA ERROR • expected 543 constituencies")
		return
	coordinator = CampaignCoordinatorScript.new(map.seats)
	_build_ui()
	_show_party_setup()
	_set_status("CHOOSE A CAMPAIGN PLATFORM")
	_push_feed("Welcome to Project 543. You need the most seats, not the most votes.")


func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)

	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui_root)

	_build_top_bar()
	_build_command_panel()
	_build_feed_panel()


func _build_top_bar() -> void:
	top_bar = PanelContainer.new()
	top_bar.anchor_right = 1.0
	top_bar.offset_left = 20.0
	top_bar.offset_top = 18.0
	top_bar.offset_right = -20.0
	top_bar.offset_bottom = 82.0
	top_bar.add_theme_stylebox_override("panel", _panel_style(Color("#101b31"), Color("#29476b"), 12))
	ui_root.add_child(top_bar)

	var margin := MarginContainer.new()
	_margin(margin, 16, 14, 16, 14)
	top_bar.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var brand := Label.new()
	brand.text = "PROJECT 543"
	brand.add_theme_font_size_override("font_size", 21)
	brand.add_theme_color_override("font_color", Color("#f4f7ff"))
	brand.custom_minimum_size.x = 180
	row.add_child(brand)

	phase_label = _top_metric(row, "PARTY SETUP", 150)
	week_label = _top_metric(row, "WEEK — / 45", 120)
	funds_label = _top_metric(row, "FUNDS ₹—", 130)
	followers_label = _top_metric(row, "FOLLOWERS —", 125)
	risk_label = _top_metric(row, "RISK 0%", 105)
	seats_label = _top_metric(row, "SEATS — / 543", 125)

	status_label = Label.new()
	status_label.text = "READY"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_color_override("font_color", Color("#8fa9ca"))
	row.add_child(status_label)


func _top_metric(parent: Node, text: String, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = width
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#c7d7ec"))
	parent.add_child(label)
	return label


func _build_command_panel() -> void:
	command_panel = PanelContainer.new()
	command_panel.anchor_left = 1.0
	command_panel.anchor_right = 1.0
	command_panel.anchor_bottom = 1.0
	command_panel.offset_left = -382.0
	command_panel.offset_top = 100.0
	command_panel.offset_right = -20.0
	command_panel.offset_bottom = -20.0
	command_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0c1629"), Color("#29476b"), 12))
	ui_root.add_child(command_panel)

	var margin := MarginContainer.new()
	_margin(margin, 16, 14, 16, 14)
	command_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	var heading := Label.new()
	heading.text = "CAMPAIGN COMMAND"
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color("#f4f7ff"))
	content.add_child(heading)

	action_status = Label.new()
	action_status.text = "Choose a platform to begin."
	action_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_status.add_theme_color_override("font_color", Color("#8fa9ca"))
	content.add_child(action_status)

	content.add_child(_section_title("TARGET INTELLIGENCE"))
	target_title = _body_label(content, "Select a constituency on the map")
	target_title.add_theme_font_size_override("font_size", 18)
	target_meta = _body_label(content, "Population — • Turnout —")
	target_support = _body_label(content, "Your projection —")
	target_leader = _body_label(content, "Current leader —")
	target_status = _body_label(content, "Status —")
	target_margin = _body_label(content, "Margin —")
	target_explanation = _body_label(content, "The map is your campaign plan.")
	target_explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_explanation.add_theme_color_override("font_color", Color("#a8bbd5"))

	var poll_row := HBoxContainer.new()
	poll_row.add_theme_constant_override("separation", 5)
	content.add_child(poll_row)
	for tier in [PollingModelScript.Tier.BASIC, PollingModelScript.Tier.STANDARD, PollingModelScript.Tier.DEEP]:
		var poll_button := Button.new()
		poll_button.text = ["POLL", "POLL+", "POLL++"][int(tier)]
		poll_button.tooltip_text = ["Basic poll: ₹10,000, ±12%", "Standard poll: ₹25,000, ±7%", "Deep poll: ₹50,000, ±3.5%"][int(tier)]
		poll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		poll_button.pressed.connect(_do_poll.bind(int(tier)))
		poll_row.add_child(poll_button)
		poll_buttons.append(poll_button)
	poll_status = _body_label(content, "No paid intelligence on this seat.")
	poll_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	content.add_child(_section_title("TWO STRATEGIC ACTIONS"))
	rally_button = _action_button(content, "RALLY", "Spend money for a permanent local push.", func() -> void: _do_action("rally"))
	interview_button = _action_button(content, "INTERVIEW", "A smaller temporary local lift.", func() -> void: _do_action("interview"))

	var manifesto_row := HBoxContainer.new()
	manifesto_row.add_theme_constant_override("separation", 6)
	content.add_child(manifesto_row)
	manifesto_select = OptionButton.new()
	manifesto_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manifesto_select.tooltip_text = "Launch a policy package. Its effect depends on the personas in each constituency."
	manifesto_row.add_child(manifesto_select)
	manifesto_button = Button.new()
	manifesto_button.text = "LAUNCH"
	manifesto_button.tooltip_text = "Use one strategic action slot to launch the selected manifesto."
	manifesto_button.pressed.connect(func() -> void: _do_manifesto())
	manifesto_row.add_child(manifesto_button)
	manifesto_status = _body_label(content, "No manifesto active.")
	manifesto_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	content.add_child(_section_title("FUNDRAISING • RISK TRADE-OFF"))
	var fund_row := HBoxContainer.new()
	fund_row.add_theme_constant_override("separation", 5)
	content.add_child(fund_row)
	for option in [100000, 250000, 500000, 1000000]:
		var fund_button := Button.new()
		fund_button.text = "₹%s" % _money(option)
		fund_button.tooltip_text = "Request ₹%s; receive 80%% and add risk." % _money(option)
		fund_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fund_button.pressed.connect(_do_fundraise.bind(option))
		fund_row.add_child(fund_button)
		fundraise_buttons.append(fund_button)

	content.add_child(_section_title("ORGANISATION"))
	var business_row := HBoxContainer.new()
	business_row.add_theme_constant_override("separation", 6)
	content.add_child(business_row)
	business_select = OptionButton.new()
	business_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	business_select.tooltip_text = "Invest now for recurring income. Every type has a 10-unit cap."
	business_row.add_child(business_select)
	business_button = Button.new()
	business_button.text = "BUILD"
	business_button.tooltip_text = "Construct the selected business using one action slot."
	business_button.pressed.connect(_do_business)
	business_row.add_child(business_button)
	business_status = _body_label(content, "No businesses established.")
	business_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	end_week_button = Button.new()
	end_week_button.text = "RESOLVE WEEK"
	end_week_button.custom_minimum_size.y = 42
	end_week_button.tooltip_text = "Resolve player and rival plans, receive income, recover risk and advance one week."
	end_week_button.pressed.connect(_resolve_week)
	content.add_child(end_week_button)

	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 6)
	content.add_child(save_row)
	save_button = Button.new()
	save_button.text = "SAVE CAMPAIGN"
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_save_game)
	save_row.add_child(save_button)
	load_button = Button.new()
	load_button.text = "LOAD CAMPAIGN"
	load_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_button.pressed.connect(_load_game)
	save_row.add_child(load_button)


func _build_feed_panel() -> void:
	feed_panel = PanelContainer.new()
	feed_panel.anchor_top = 1.0
	feed_panel.anchor_bottom = 1.0
	feed_panel.offset_left = 20.0
	feed_panel.offset_top = -154.0
	feed_panel.offset_right = 620.0
	feed_panel.offset_bottom = -20.0
	feed_panel.add_theme_stylebox_override("panel", _panel_style(Color("#0c1629"), Color("#213b5d"), 12))
	ui_root.add_child(feed_panel)

	var margin := MarginContainer.new()
	_margin(margin, 14, 10, 14, 10)
	feed_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var title := Label.new()
	title.text = "CAMPAIGN BRIEFING"
	title.add_theme_color_override("font_color", Color("#88b8e8"))
	box.add_child(title)
	feed_label = RichTextLabel.new()
	feed_label.bbcode_enabled = true
	feed_label.fit_content = false
	feed_label.scroll_active = false
	feed_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feed_label.add_theme_color_override("default_color", Color("#b4c4da"))
	box.add_child(feed_label)


func _section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#6fa9df"))
	return label


func _body_label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("#d2def0"))
	parent.add_child(label)
	return label


func _action_button(parent: Node, title: String, tooltip: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.tooltip_text = tooltip
	button.custom_minimum_size.y = 36
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _show_party_setup() -> void:
	_clear_overlay(setup_overlay)
	party_choice_buttons.clear()
	setup_overlay = PanelContainer.new()
	setup_overlay.anchor_left = 0.5
	setup_overlay.anchor_right = 0.5
	setup_overlay.anchor_top = 0.5
	setup_overlay.anchor_bottom = 0.5
	setup_overlay.offset_left = -430.0
	setup_overlay.offset_top = -235.0
	setup_overlay.offset_right = 430.0
	setup_overlay.offset_bottom = 235.0
	setup_overlay.add_theme_stylebox_override("panel", _panel_style(Color("#101d35"), Color("#3b6e9e"), 16))
	ui_root.add_child(setup_overlay)

	var margin := MarginContainer.new()
	_margin(margin, 28, 24, 28, 24)
	setup_overlay.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "PROJECT 543"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#f4f7ff"))
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "BUILD A NATIONAL CAMPAIGN"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#79b6e8"))
	box.add_child(subtitle)
	var intro := Label.new()
	intro.text = "Choose a platform. Your ideology determines where you start strong; your two actions each week determine whether you can turn that strength into seats."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color", Color("#bccce2"))
	box.add_child(intro)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	var specs := coordinator.config.party_specs()
	for spec in specs:
		var party_id := String(spec.get("id", ""))
		var choice := Button.new()
		choice.text = "%s\n%s" % [String(spec.get("name", party_id)), _platform_description(String(spec.get("personality", "player")))]
		choice.custom_minimum_size = Vector2(0, 70)
		choice.tooltip_text = "Select %s as your platform." % String(spec.get("name", party_id))
		choice.pressed.connect(_select_preset.bind(party_id))
		grid.add_child(choice)
		party_choice_buttons[party_id] = choice
	_select_preset(selected_preset)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	box.add_child(name_row)
	var name_caption := Label.new()
	name_caption.text = "PARTY NAME"
	name_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_row.add_child(name_caption)
	party_name_edit = LineEdit.new()
	party_name_edit.max_length = 32
	party_name_edit.placeholder_text = "Use the platform name or create your own"
	party_name_edit.text = "National Reform"
	party_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_name_edit.tooltip_text = "A memorable name helps you read the election result."
	name_row.add_child(party_name_edit)

	var continue_button := Button.new()
	continue_button.text = "CONTINUE • CHOOSE HOME CONSTITUENCY"
	continue_button.custom_minimum_size.y = 44
	continue_button.pressed.connect(_begin_home_selection)
	box.add_child(continue_button)
	var hint := Label.new()
	hint.text = "You can inspect the map now; the home constituency adds +2% base support."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("#7894b5"))
	box.add_child(hint)


func _select_preset(preset_id: String) -> void:
	selected_preset = preset_id
	var spec := _party_spec(preset_id)
	if party_name_edit != null and party_name_edit.text.strip_edges().is_empty():
		party_name_edit.text = String(spec.get("name", "National Reform"))
	for party_id in party_choice_buttons.keys():
		var button: Button = party_choice_buttons[party_id]
		button.modulate = Color("#8bc8ff") if String(party_id) == preset_id else Color.WHITE
	if party_name_edit != null and party_name_edit.text == "National Reform" and preset_id != "party_player":
		party_name_edit.text = String(spec.get("name", "National Reform"))


func _begin_home_selection() -> void:
	var name := party_name_edit.text.strip_edges() if party_name_edit != null else ""
	var result := coordinator.start_new_campaign(selected_preset, name)
	if not bool(result.get("ok", false)):
		_push_feed("Unable to start campaign: %s" % _errors(result))
		return
	_clear_overlay(setup_overlay)
	pending_home_id = ""
	_show_home_selection()
	_set_status("SELECT A HOME CONSTITUENCY ON THE MAP")
	_refresh_ui()


func _show_home_selection() -> void:
	_clear_overlay(home_overlay)
	home_overlay = PanelContainer.new()
	home_overlay.anchor_left = 0.5
	home_overlay.anchor_right = 0.5
	home_overlay.offset_left = -270.0
	home_overlay.offset_top = 108.0
	home_overlay.offset_right = 270.0
	home_overlay.offset_bottom = 220.0
	home_overlay.add_theme_stylebox_override("panel", _panel_style(Color("#132742"), Color("#4383b7"), 12))
	ui_root.add_child(home_overlay)
	var margin := MarginContainer.new()
	_margin(margin, 16, 12, 16, 12)
	home_overlay.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var title := Label.new()
	title.text = "HOME CONSTITUENCY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#8bc8ff"))
	box.add_child(title)
	home_candidate_label = Label.new()
	home_candidate_label.text = "Click a seat on the map to nominate it."
	home_candidate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_candidate_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(home_candidate_label)
	confirm_home_button = Button.new()
	confirm_home_button.text = "CONFIRM HOME"
	confirm_home_button.disabled = true
	confirm_home_button.pressed.connect(_confirm_home)
	box.add_child(confirm_home_button)


func _confirm_home() -> void:
	if pending_home_id.is_empty():
		return
	var result := coordinator.confirm_home(pending_home_id)
	if not bool(result.get("ok", false)):
		_push_feed("Home constituency could not be secured: %s" % _errors(result))
		return
	_clear_overlay(home_overlay)
	selected_id = pending_home_id
	pending_home_id = ""
	tutorial_shown = false
	_set_status("CAMPAIGN ACTIVE • PLAN YOUR FIRST TWO ACTIONS")
	_push_feed("Campaign active. Protect your home base, then find the seats you can actually flip.")
	_refresh_ui()
	_show_tutorial()


func _on_constituency_selected(seat: Dictionary) -> void:
	var id := String(seat.get("unique_id", ""))
	if coordinator == null or id.is_empty():
		return
	selected_id = id
	coordinator.select_constituency(id)
	if coordinator.phase == CampaignCoordinatorScript.SETUP_HOME:
		pending_home_id = id
		if home_candidate_label != null:
			home_candidate_label.text = "%s • %s" % [coordinator.constituency_name(id), String(seat.get("state_ut_name", "Unknown"))]
		if confirm_home_button != null:
			confirm_home_button.disabled = false
		_set_status("HOME CANDIDATE SELECTED • CONFIRM TO BEGIN")
	_refresh_ui()


func _on_constituency_hovered(seat: Dictionary) -> void:
	if coordinator == null:
		return
	if selected_id.is_empty() or coordinator.phase == CampaignCoordinatorScript.SETUP_HOME:
		_set_status("HOVER • %s" % String(seat.get("ls_seat_name", "CONSTITUENCY")))


func _on_constituency_cleared() -> void:
	if coordinator != null and coordinator.phase == CampaignCoordinatorScript.SETUP_HOME:
		pending_home_id = ""
		if home_candidate_label != null:
			home_candidate_label.text = "Click a seat on the map to nominate it."
		if confirm_home_button != null:
			confirm_home_button.disabled = true
	selected_id = ""
	_refresh_ui()


func _do_action(action_type: String) -> void:
	var result := coordinator.execute_player_action(action_type, selected_id)
	_handle_action_result(result)


func _do_manifesto() -> void:
	var id := _selected_option_value(manifesto_select)
	if id.is_empty():
		return
	var result := coordinator.execute_player_action("manifesto", "", id)
	_handle_action_result(result)


func _do_fundraise(amount: int) -> void:
	_handle_action_result(coordinator.execute_player_action("fundraise", "", str(amount)))


func _do_business() -> void:
	var id := _selected_option_value(business_select)
	if id.is_empty():
		return
	_handle_action_result(coordinator.execute_player_action("business", "", id))


func _handle_action_result(result: Dictionary) -> void:
	if bool(result.get("ok", false)):
		_push_feed(String(result.get("message", "Action completed.")))
		_set_status("ACTION COMMITTED • %d SLOT(S) REMAINING" % int(result.get("actions_remaining", coordinator.get_summary().get("actions_remaining", 0))))
	else:
		_push_feed("Action blocked: %s" % _errors(result))
		_set_status("ACTION NOT COMMITTED")
	_refresh_ui()


func _do_poll(tier: int) -> void:
	if selected_id.is_empty():
		_push_feed("Select a constituency before buying intelligence.")
		return
	var result := coordinator.conduct_poll(selected_id, int(tier))
	if bool(result.get("ok", false)):
		_push_feed("Paid intelligence received for %s." % coordinator.constituency_name(selected_id))
	else:
		_push_feed("Poll blocked: %s" % _errors(result))
	_refresh_ui()


func _resolve_week() -> void:
	var result := coordinator.resolve_week()
	if not bool(result.get("ok", false)):
		_push_feed("Week could not resolve: %s" % _errors(result))
		return
	var income: Array = result.get("income", [])
	var player_income := 0
	for item in income:
		if String(item.get("party_id", "")) == CampaignCoordinatorScript.PLAYER_PARTY_ID:
			player_income += int(item.get("amount", 0))
	if player_income > 0:
		_push_feed("Income phase: ₹%s received from your businesses." % _money(player_income))
	var ai_actions: Array = result.get("ai_actions", [])
	if not ai_actions.is_empty():
		_push_feed("Rivals committed %d actions. The map has moved." % ai_actions.size())
	if coordinator.is_election_ready():
		_set_status("ELECTION READY • POLLING HAS CLOSED")
		_push_feed("Polling closed. Every constituency is now being counted.")
		_show_election_results()
	else:
		_set_status("WEEK %02d ACTIVE • REASSESS THE MAP" % coordinator.turn)
	_refresh_ui()


func _refresh_ui() -> void:
	if coordinator == null:
		return
	var summary := coordinator.get_summary()
	phase_label.text = _phase_text(String(summary.get("phase", "")))
	week_label.text = "WEEK %02d / %02d" % [int(summary.get("turn", 1)), int(summary.get("weeks", 45))]
	funds_label.text = "FUNDS ₹%s" % _money(int(summary.get("money", 0)))
	followers_label.text = "FOLLOWERS %s" % _money(int(summary.get("followers", 0)))
	risk_label.text = "RISK %.0f%%" % (float(summary.get("risk", 0.0)) * 100.0)
	risk_label.add_theme_color_override("font_color", Color("#ff9d8b") if float(summary.get("risk", 0.0)) >= 0.5 else Color("#c7d7ec"))
	seats_label.text = "SEATS %d / 543" % int(summary.get("forecast_seats", 0))
	if coordinator.phase == CampaignCoordinatorScript.ACTIVE:
		action_status.text = "%d / 2 strategic actions committed • click RESOLVE WEEK when ready" % int(summary.get("actions_used", 0))
	elif coordinator.phase == CampaignCoordinatorScript.SETUP_HOME:
		action_status.text = "Choose a seat for your home base. It receives +2% base support."
	elif coordinator.phase == CampaignCoordinatorScript.SETUP_PARTY:
		action_status.text = "Choose a party platform to start."
	else:
		action_status.text = "Election results are final. Review the races that decided the map."

	var leaders := coordinator.get_map_leaders()
	var home_id := String(summary.get("home_constituency_id", ""))
	if coordinator.phase == CampaignCoordinatorScript.SETUP_HOME:
		home_id = pending_home_id
	map.bind_campaign_view(leaders, coordinator.get_party_colours(), home_id, coordinator.is_election_ready())
	_update_target_panel()
	_update_action_controls()
	_update_feed_from_events()


func _update_target_panel() -> void:
	if selected_id.is_empty() or coordinator == null or not coordinator.constituencies.has(selected_id):
		target_title.text = "Select a constituency on the map"
		target_meta.text = "Population — • Turnout —"
		target_support.text = "Your projection —"
		target_leader.text = "Current leader —"
		target_status.text = "Status —"
		target_margin.text = "Margin —"
		target_explanation.text = "The map is your campaign plan. Look for close races where one good action changes the outcome."
		poll_status.text = "No paid intelligence on this seat."
		return
	var constituency := coordinator.get_constituency(selected_id)
	var result := coordinator.get_constituency_result(selected_id)
	var support: Dictionary = result.get("support", {})
	var player_support := float(support.get(CampaignCoordinatorScript.PLAYER_PARTY_ID, 0.0))
	var leader_id := String(result.get("winner_party_id", ""))
	var leader_support := float(support.get(leader_id, 0.0))
	var margin := absf(leader_support - player_support)
	var status := _contest_status(leader_id == CampaignCoordinatorScript.PLAYER_PARTY_ID, margin)
	target_title.text = constituency.name
	target_meta.text = "%s • Population %s • Turnout %.0f%%" % [constituency.state_ut, _short_number(constituency.population), constituency.turnout * 100.0]
	target_support.text = "YOUR PROJECTION  %.1f%%" % (player_support * 100.0)
	target_leader.text = "LEADING  %s  %.1f%%" % [coordinator.party_name(leader_id), leader_support * 100.0]
	target_status.text = "STATUS  %s" % status
	target_status.add_theme_color_override("font_color", Color("#74d6b1") if status in ["LEADING", "SAFE WIN"] else Color("#f4c76a") if status == "COMPETITIVE" else Color("#ff9d8b"))
	target_margin.text = "MARGIN  %.1f points" % (margin * 100.0)
	target_explanation.text = _explain_target(result, leader_id)

	var report := coordinator.get_report(selected_id)
	if report.is_empty():
		poll_status.text = "No paid intelligence on this seat."
	elif coordinator.report_is_stale(selected_id):
		poll_status.text = "POLL STALE • refresh before trusting it"
	else:
		var poll_player: Dictionary = report.get("results", {}).get(CampaignCoordinatorScript.PLAYER_PARTY_ID, {})
		poll_status.text = "POLL %s • %.1f%% [%.1f–%.1f%%]" % [String(report.get("tier", "")), float(poll_player.get("estimate", 0.0)) * 100.0, float(poll_player.get("lower", 0.0)) * 100.0, float(poll_player.get("upper", 0.0)) * 100.0]


func _update_action_controls() -> void:
	var active := coordinator != null and coordinator.phase == CampaignCoordinatorScript.ACTIVE
	var has_target := not selected_id.is_empty()
	var remaining := int(coordinator.get_summary().get("actions_remaining", 0)) if coordinator != null else 0
	var can_action := active and has_target and remaining > 0
	rally_button.disabled = not can_action
	interview_button.disabled = not can_action
	manifesto_button.disabled = not active or remaining <= 0
	business_button.disabled = not active or remaining <= 0
	end_week_button.disabled = not active
	for button in fundraise_buttons:
		button.disabled = not active or remaining <= 0
	for button in poll_buttons:
		button.disabled = not active or not has_target
	save_button.disabled = not active and not coordinator.is_election_ready()
	load_button.disabled = false

	var rally := coordinator.config.action("rally")
	var interview := coordinator.config.action("interview")
	rally_button.text = "RALLY  •  ₹%s  •  +%.1f%%" % [_money(int(rally.get("cost", 0))), float(rally.get("support_effect", 0.0)) * 100.0]
	interview_button.text = "INTERVIEW  •  ₹%s  •  +%.1f%% temporary" % [_money(int(interview.get("cost", 0))), float(interview.get("support_effect", 0.0)) * 100.0]
	_update_option_buttons()


func _update_option_buttons() -> void:
	if manifesto_select.get_item_count() == 0:
		for manifesto in coordinator.config.manifestos():
			manifesto_select.add_item("%s • ₹%s" % [String(manifesto.get("name", "Manifesto")), _money(int(manifesto.get("cost", 0)))])
			manifesto_select.set_item_metadata(manifesto_select.get_item_count() - 1, String(manifesto.get("id", "")))
	var active_manifesto := coordinator.get_active_manifesto()
	if active_manifesto.is_empty():
		manifesto_status.text = "No manifesto active. Match policy packages to constituency personas."
	else:
		manifesto_status.text = "ACTIVE  %s • expires after week %d" % [String(active_manifesto.get("name", "")), int(active_manifesto.get("expires_turn", coordinator.turn)) - 1]

	if business_select.get_item_count() == 0:
		for business in coordinator.config.businesses():
			business_select.add_item("%s • ₹%s → ₹%s/week" % [String(business.get("name", "")), _money(int(business.get("cost", 0))), _money(int(business.get("income", 0)))])
			business_select.set_item_metadata(business_select.get_item_count() - 1, String(business.get("id", "")))
	var business_lines: Array[String] = []
	for business in coordinator.config.businesses():
		var business_id := String(business.get("id", ""))
		var count := coordinator.get_business_count(business_id)
		business_lines.append("%s %d/%d" % [String(business.get("name", "")), count, int(business.get("limit", 10))])
	business_status.text = "Businesses: " + " • ".join(business_lines)


func _update_feed_from_events() -> void:
	if feed_label == null or coordinator == null:
		return
	var lines: Array[String] = []
	for event in coordinator.get_event_log(7):
		lines.append("[color=#789bc2]W%02d[/color]  %s" % [int(event.get("turn", 1)), String(event.get("message", ""))])
	feed_label.text = "\n".join(lines)


func _show_tutorial() -> void:
	if tutorial_shown or ui_root == null:
		return
	tutorial_shown = true
	var dialog := AcceptDialog.new()
	dialog.title = "FIELD BRIEFING • HOW TO WIN PROJECT 543"
	dialog.dialog_text = "The map is your campaign plan. Click any constituency to inspect its projected support and margin.\n\nEach week you have two actions: rally for a permanent local lift, interview for a temporary lift, launch a persona-matched manifesto, raise money with risk, or build a business for recurring income.\n\nPaid polls are estimates, not truth. The seat forecast is first-past-the-post: a narrow win is worth the same seat as a landslide. Resolve the week when your plan is ready."
	dialog.ok_button_text = "START WEEK 1"
	ui_root.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.popup_centered(Vector2(620, 430))


func _show_election_results() -> void:
	_clear_overlay(results_overlay)
	var result := coordinator.get_election_result()
	if result == null:
		return
	results_overlay = PanelContainer.new()
	results_overlay.anchor_left = 0.5
	results_overlay.anchor_right = 0.5
	results_overlay.anchor_top = 0.5
	results_overlay.anchor_bottom = 0.5
	results_overlay.offset_left = -410.0
	results_overlay.offset_top = -270.0
	results_overlay.offset_right = 410.0
	results_overlay.offset_bottom = 270.0
	results_overlay.add_theme_stylebox_override("panel", _panel_style(Color("#111f38"), Color("#e4b65d"), 16))
	ui_root.add_child(results_overlay)
	var margin := MarginContainer.new()
	_margin(margin, 26, 22, 26, 22)
	results_overlay.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var title := Label.new()
	title.text = "ELECTION NIGHT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#ffe0a0"))
	box.add_child(title)
	var winner := coordinator.party_name(result.winner_party_id)
	var player_seats := int(result.seat_totals.get(CampaignCoordinatorScript.PLAYER_PARTY_ID, 0))
	var outcome := "VICTORY • LARGEST PARTY" if result.winner_party_id == CampaignCoordinatorScript.PLAYER_PARTY_ID else "DEFEAT • STUDY THE MAP"
	var outcome_label := Label.new()
	outcome_label.text = "%s\n%s" % [winner, outcome]
	outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_label.add_theme_font_size_override("font_size", 20)
	box.add_child(outcome_label)
	var table := RichTextLabel.new()
	table.bbcode_enabled = true
	table.fit_content = true
	table.custom_minimum_size.y = 210
	var rows := "[center][font_size=18]FINAL SEAT COUNT[/font_size]\n\n"
	var ordered := []
	for party_id in result.seat_totals.keys():
		ordered.append(String(party_id))
	ordered.sort_custom(func(a, b):
		var seats_a := int(result.seat_totals[a])
		var seats_b := int(result.seat_totals[b])
		return seats_a > seats_b if seats_a != seats_b else a < b
	)
	for party_id in ordered:
		var definition := coordinator.get_party_definition(party_id)
		var colour := definition.colour if definition != null else "#d2def0"
		rows += "[color=%s]%-24s %3d seats[/color]\n" % [colour, coordinator.party_name(party_id), int(result.seat_totals[party_id])]
	rows += "\n%s\nPlayer result: %d seats%s[/center]" % ["MAJORITY: 272", player_seats, " • MAJORITY" if player_seats >= 272 else ""]
	table.text = rows
	box.add_child(table)
	var close_races := Button.new()
	close_races.text = "REVIEW CLOSEST RACES"
	close_races.pressed.connect(_show_closest_races)
	box.add_child(close_races)
	var new_campaign := Button.new()
	new_campaign.text = "NEW CAMPAIGN"
	new_campaign.pressed.connect(_new_campaign)
	box.add_child(new_campaign)
	_refresh_ui()


func _show_closest_races() -> void:
	var result := coordinator.get_election_result()
	if result == null:
		return
	var races: Array = result.constituency_results.duplicate(true)
	races.sort_custom(func(a, b): return int(a.get("margin_votes", 0)) < int(b.get("margin_votes", 0)))
	var text := "The narrowest races shaped the result.\n\n"
	for index in range(mini(12, races.size())):
		var race: Dictionary = races[index]
		text += "%s — %s — %s votes\n" % [String(race.get("name", "")), coordinator.party_name(String(race.get("winner_party_id", ""))), _money(int(race.get("margin_votes", 0)))]
	var dialog := AcceptDialog.new()
	dialog.title = "CLOSEST RACES • EXPLAINABLE RESULT"
	dialog.dialog_text = text
	ui_root.add_child(dialog)
	dialog.popup_centered(Vector2(650, 500))


func _new_campaign() -> void:
	_clear_overlay(results_overlay)
	coordinator = CampaignCoordinatorScript.new(map.seats)
	selected_id = ""
	pending_home_id = ""
	selected_preset = "party_player"
	tutorial_shown = false
	map.clear_selection()
	_show_party_setup()
	_set_status("CHOOSE A NEW CAMPAIGN PLATFORM")
	_push_feed("New campaign ready. A different platform changes which constituencies are naturally receptive.")
	_refresh_ui()


func _save_game() -> void:
	if coordinator == null:
		return
	var data := coordinator.to_dictionary()
	var temp_name := "project543_campaign.json.tmp"
	var temp_path := "user://" + temp_name
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		_push_feed("Save failed: storage is unavailable.")
		return
	file.store_string(JSON.stringify(data))
	file.close()
	var user_directory := DirAccess.open("user://")
	var rename_error := user_directory.rename(temp_name, "project543_campaign.json") if user_directory != null else ERR_CANT_OPEN
	if rename_error != OK:
		var fallback := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if fallback == null:
			_push_feed("Save failed: could not replace the campaign file.")
			return
		fallback.store_string(JSON.stringify(data))
		fallback.close()
		if user_directory != null:
			user_directory.remove(temp_name)
	_push_feed("Campaign saved safely at Week %02d." % coordinator.turn)
	_set_status("CAMPAIGN SAVED")


func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_push_feed("No saved campaign found.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_push_feed("Load failed: save file could not be opened.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_push_feed("Load failed safely: the save file is not valid JSON.")
		return
	var restored := CampaignCoordinatorScript.from_dictionary(map.seats, parsed)
	if restored == null:
		_push_feed("Load failed safely: this campaign is incompatible or corrupted.")
		return
	coordinator = restored
	map.clear_selection()
	selected_id = coordinator.get_selected_id()
	_clear_overlay(setup_overlay)
	_clear_overlay(home_overlay)
	_clear_overlay(results_overlay)
	if coordinator.phase == CampaignCoordinatorScript.SETUP_PARTY:
		_show_party_setup()
	elif coordinator.phase == CampaignCoordinatorScript.SETUP_HOME:
		_show_home_selection()
	elif coordinator.is_election_ready():
		_show_election_results()
	_push_feed("Campaign loaded. All strategic state and financial history restored.")
	_set_status("CAMPAIGN LOADED")
	_refresh_ui()


func _show_boot_error(message: String) -> void:
	push_error(message)
	var label := Label.new()
	label.text = message
	label.position = Vector2(40, 40)
	label.add_theme_color_override("font_color", Color("#ff8a80"))
	add_child(label)


func _phase_text(value: String) -> String:
	match value:
		CampaignCoordinatorScript.SETUP_PARTY:
			return "PARTY SETUP"
		CampaignCoordinatorScript.SETUP_HOME:
			return "HOME SELECTION"
		CampaignCoordinatorScript.ACTIVE:
			return "CAMPAIGN ACTIVE"
		CampaignCoordinatorScript.ELECTION_READY, CampaignCoordinatorScript.COMPLETED:
			return "ELECTION RESULTS"
	return value.to_upper()


func _platform_description(personality: String) -> String:
	match personality:
		"economic":
			return "investment & growth"
		"regional":
			return "regional organisation"
		"campaigner":
			return "high-pressure campaigning"
	return "balanced reform"


func _party_spec(party_id: String) -> Dictionary:
	for spec in coordinator.config.party_specs():
		if String(spec.get("id", "")) == party_id:
			return spec
	return {}


func _contest_status(player_leads: bool, margin: float) -> String:
	if player_leads:
		return "SAFE WIN" if margin >= 0.10 else "LEADING"
	return "COMPETITIVE" if margin < 0.05 else "LIKELY LOSS" if margin < 0.12 else "SAFE LOSS"


func _explain_target(result: Dictionary, leader_id: String) -> String:
	var explanation: Dictionary = result.get("explanations", {}).get(CampaignCoordinatorScript.PLAYER_PARTY_ID, {})
	var affinity := float(explanation.get("constituency_affinity", 0.0))
	var campaign := float(explanation.get("campaign_bonus", 0.0))
	var risk_modifier := float(explanation.get("risk_modifier", 1.0))
	var line := "Structural fit %.0f%% • campaign lift %.1f points" % [affinity * 100.0, campaign * 100.0]
	if risk_modifier < 1.0:
		line += " • scandal penalty active"
	if leader_id == CampaignCoordinatorScript.PLAYER_PARTY_ID:
		line += ". Protect this lead."
	else:
		line += ". Spend here only if the margin justifies the opportunity cost."
	return line


func _selected_option_value(option: OptionButton) -> String:
	if option == null or option.get_item_count() == 0 or option.selected < 0:
		return ""
	return String(option.get_item_metadata(option.selected))


func _clear_overlay(overlay: Control) -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()


func _set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text


func _push_feed(message: String) -> void:
	if feed_label == null:
		return
	var lines := feed_label.text.split("\n") if not feed_label.text.is_empty() else []
	lines.append("[color=#789bc2]NOW[/color]  " + message)
	while lines.size() > 7:
		lines.pop_front()
	feed_label.text = "\n".join(lines)


func _errors(result: Dictionary) -> String:
	var errors: Array = result.get("errors", [])
	return String(errors[0]) if not errors.is_empty() else String(result.get("code", "Unknown error"))


func _margin(container: Container, left: int, top: int, right: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_bottom", bottom)


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 10
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _money(value: int) -> String:
	var text := str(value)
	var output := ""
	var count := 0
	for index in range(text.length() - 1, -1, -1):
		output = text[index] + output
		count += 1
		if count == 3 and index > 0:
			output = "," + output
			count = 0
	return output


func _short_number(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.0fk" % (float(value) / 1000.0)
	return str(value)
