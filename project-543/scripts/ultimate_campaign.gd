extends Node

## Project 543 V0.1 playable campaign shell.
## Keeps the proven 543-seat GIS world and drives a complete 45-week campaign:
## party identity, two actions/week, economy, risk, constituency targeting,
## AI turns, save/load, deterministic election and explainable results.
##
## Simulation values live in this controller because the existing repository
## does not yet expose a single canonical end-to-end campaign coordinator.
## They are deliberately named and centralized for later data/config migration.

const WEEKS := 45
const ACTIONS_PER_WEEK := 2
const STARTING_MONEY := 500000
const STARTING_FOLLOWERS := 100
const SAVE_PATH := "user://project543_save.json"
const GAME_SEED := 543051

const PARTY_NAMES := [
	"National Reform",
	"Development Front",
	"People's Coalition",
	"Civic Alliance"
]
const PARTY_COLOURS := [Color("#3B82F6"), Color("#F97316"), Color("#22C55E"), Color("#A855F7")]

var host: Node
var map: Node
var seats: Array = []
var rng_seed := GAME_SEED
var campaign_started := false
var campaign_finished := false
var week := 1
var actions_used := 0
var money := STARTING_MONEY
var followers := STARTING_FOLLOWERS
var risk := 0.0
var businesses := 0
var selected_id := ""
var selected_name := ""
var selected_state := ""
var campaign_delta: Dictionary = {}
var base_scores: Dictionary = {}
var ai_scores: Dictionary = {}
var player_manifesto := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var history: Array = []
var results: Array = []

var root_ui: Control
var status_label: Label
var week_label: Label
var money_label: Label
var risk_label: Label
var follower_label: Label
var target_label: Label
var support_label: Label
var action_label: Label
var log_label: RichTextLabel
var results_panel: PanelContainer
var results_text: RichTextLabel
var start_overlay: PanelContainer
var action_buttons: Array[Button] = []

func _ready() -> void:
	host = get_parent()
	call_deferred("_boot")

func _boot() -> void:
	map = host.get_node_or_null("IndiaMap")
	if map == null:
		return
	seats = map.seats
	if seats.size() != 543:
		return
	if map.has_signal("constituency_selected"):
		map.constituency_selected.connect(_on_seat_selected)
	_build_ui()
	_generate_world()
	_show_start_screen()

func _generate_world() -> void:
	base_scores.clear()
	ai_scores.clear()
	campaign_delta.clear()
	for i in range(seats.size()):
		var id := str(seats[i].get("unique_id", "C%03d" % (i + 1)))
		var h := _hash_int(id + str(GAME_SEED))
		base_scores[id] = {
			"player": 0.16 + float(h % 3000) / 10000.0,
			"alpha": 0.16 + float((h / 7) % 3000) / 10000.0,
			"beta": 0.16 + float((h / 13) % 3000) / 10000.0,
			"gamma": 0.16 + float((h / 29) % 3000) / 10000.0
		}
		campaign_delta[id] = 0.0

func _build_ui() -> void:
	root_ui = Control.new()
	root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(root_ui)

	var right := PanelContainer.new()
	right.position = Vector2(930, 100)
	right.size = Vector2(330, 590)
	right.mouse_filter = Control.MOUSE_FILTER_STOP
	root_ui.add_child(right)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	right.add_child(box)

	var title := Label.new()
	title.text = "CAMPAIGN COMMAND"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	week_label = _label(box, "WEEK 01 / 45")
	money_label = _label(box, "FUNDS ₹5,00,000")
	follower_label = _label(box, "FOLLOWERS 100")
	risk_label = _label(box, "RISK 0")
	action_label = _label(box, "ACTIONS 0 / 2")
	box.add_child(HSeparator.new())
	target_label = _label(box, "TARGET: Select a constituency")
	support_label = _label(box, "YOUR SUPPORT: —")

	var intelligence := Button.new()
	intelligence.text = "INTELLIGENCE"
	intelligence.tooltip_text = "Inspect the selected constituency."
	intelligence.pressed.connect(_intelligence)
	box.add_child(intelligence)

	var actions_title := Label.new()
	actions_title.text = "STRATEGIC ACTIONS"
	actions_title.add_theme_font_size_override("font_size", 16)
	box.add_child(actions_title)

	_add_action(box, "RALLY  •  ₹50,000", "rally", 50000)
	_add_action(box, "INTERVIEW  •  ₹20,000", "interview", 20000)
	_add_action(box, "MANIFESTO  •  ₹30,000", "manifesto", 30000)
	_add_action(box, "FUNDRAISE  •  ₹0", "fundraise", 0)
	_add_action(box, "BUILD BUSINESS  •  ₹1,50,000", "business", 150000)

	box.add_child(HSeparator.new())
	var end_week := Button.new()
	end_week.text = "RESOLVE WEEK"
	end_week.pressed.connect(_resolve_week)
	box.add_child(end_week)

	var save := Button.new()
	save.text = "SAVE CAMPAIGN"
	save.pressed.connect(_save_game)
	box.add_child(save)

	var load := Button.new()
	load.text = "LOAD CAMPAIGN"
	load.pressed.connect(_load_game)
	box.add_child(load)

	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.fit_content = true
	log_label.custom_minimum_size = Vector2(0, 130)
	box.add_child(log_label)

func _label(parent: Node, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _add_action(parent: Node, text: String, action: String, cost: int) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func(): _perform_action(action, cost))
	parent.add_child(b)
	action_buttons.append(b)

func _show_start_screen() -> void:
	start_overlay = PanelContainer.new()
	start_overlay.position = Vector2(280, 150)
	start_overlay.size = Vector2(600, 420)
	root_ui.add_child(start_overlay)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	start_overlay.add_child(box)
	var title := Label.new()
	title.text = "PROJECT 543"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "THE NATIONAL CAMPAIGN"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	box.add_child(sub)
	var info := RichTextLabel.new()
	info.bbcode_enabled = true
	info.text = "[center]45 weeks • 543 constituencies • 2 actions per week[/center]\n\nBuild a party, choose where to fight, manage money and risk, and try to win the most seats.\n\n[font_size=16]Click START CAMPAIGN to begin.[/font_size]"
	info.custom_minimum_size = Vector2(0, 190)
	box.add_child(info)
	var start := Button.new()
	start.text = "START CAMPAIGN"
	start.custom_minimum_size = Vector2(0, 52)
	start.pressed.connect(_start_campaign)
	box.add_child(start)

func _start_campaign() -> void:
	campaign_started = true
	campaign_finished = false
	week = 1
	actions_used = 0
	money = STARTING_MONEY
	followers = STARTING_FOLLOWERS
	risk = 0.0
	businesses = 0
	history.clear()
	results.clear()
	if start_overlay:
		start_overlay.queue_free()
	_update_ui()
	_log("Campaign started. Select a constituency on the map.")

func _on_seat_selected(seat: Dictionary) -> void:
	selected_id = str(seat.get("unique_id", ""))
	selected_name = str(seat.get("ls_seat_name", selected_id))
	selected_state = str(seat.get("state_ut_name", "Unknown"))
	_update_ui()
	if campaign_started and not campaign_finished:
		_log("Target acquired: %s, %s." % [selected_name, selected_state])

func _intelligence() -> void:
	if selected_id.is_empty():
		_log("Select a constituency first.")
		return
	var base: Dictionary = base_scores[selected_id]
	var player := float(base.player) + float(campaign_delta[selected_id])
	var leaders := ["player", "alpha", "beta", "gamma"]
	leaders.sort_custom(func(a, b): return float(base[a]) > float(base[b]))
	_log("INTELLIGENCE • %s: your %.1f%% • strongest rival %.1f%%." % [selected_name, player * 100.0, float(base[leaders[0]]) * 100.0])

func _perform_action(action: String, cost: int) -> void:
	if not campaign_started or campaign_finished:
		return
	if actions_used >= ACTIONS_PER_WEEK:
		_log("Two actions are already committed this week.")
		return
	if action != "fundraise" and money < cost:
		_log("Insufficient funds.")
		return
	if action in ["rally", "interview", "manifesto"] and selected_id.is_empty():
		_log("Choose a constituency before campaigning.")
		return

	if cost > 0:
		money -= cost

	match action:
		"rally":
			campaign_delta[selected_id] = float(campaign_delta[selected_id]) + 0.035
			risk += 2.0
			followers += 15
			_log("Rally held in %s: local support rises." % selected_name)
		"interview":
			campaign_delta[selected_id] = float(campaign_delta[selected_id]) + 0.018
			risk += 0.5
			_log("National interview completed: measured local gain, low risk.")
		"manifesto":
			for id in campaign_delta.keys():
				campaign_delta[id] = float(campaign_delta[id]) + 0.004
			risk += 1.0
			_log("Manifesto launched: a small national support movement.")
		"fundraise":
			var gain := 90000 + int(followers * 40)
			money += gain
			risk += 1.0
			_log("Fundraising drive raised ₹%s." % _money(gain))
		"business":
			businesses += 1
			risk += 0.25
			_log("Business established. Recurring income will arrive each week.")

	actions_used += 1
	history.append({"week": week, "action": action, "target": selected_id})
	_update_ui()

func _resolve_week() -> void:
	if not campaign_started or campaign_finished:
		return
	if actions_used == 0:
		_log("No action committed. Resolve anyway or choose an action.")
	var income := businesses * 25000
	money += income
	if income > 0:
		_log("Weekly business income: ₹%s." % _money(income))

	_ai_turn()
	actions_used = 0
	risk = maxf(0.0, risk - 0.25)
	if week >= WEEKS:
		_resolve_election()
		return
	week += 1
	_update_ui()
	_log("Week %02d begins. Intelligence → Actions → Resolution." % week)

func _ai_turn() -> void:
	var targets: Array = []
	for id in base_scores.keys():
		var gap := float(base_scores[id].alpha) - float(base_scores[id].player) - float(campaign_delta[id])
		if gap > 0.0:
			targets.append([gap, id])
	targets.sort_custom(func(a, b): return a[0] > b[0])
	var count := mini(2, targets.size())
	for i in range(count):
		var id: String = targets[i][1]
		ai_scores[id] = float(ai_scores.get(id, 0.0)) + 0.012

func _resolve_election() -> void:
	campaign_finished = true
	results.clear()
	var totals := {"player": 0, "alpha": 0, "beta": 0, "gamma": 0}
	for id in base_scores.keys():
		var scores: Dictionary = base_scores[id].duplicate(true)
		scores.player = clampf(float(scores.player) + float(campaign_delta[id]), 0.0, 1.0)
		scores.alpha = clampf(float(scores.alpha) + float(ai_scores.get(id, 0.0)), 0.0, 1.0)
		var winner := _winner(scores)
		totals[winner] = int(totals[winner]) + 1
		results.append({
			"id": id,
			"name": _seat_name(id),
			"winner": winner,
			"scores": scores
		})
	_show_results(totals)

func _winner(scores: Dictionary) -> String:
	var ids := ["player", "alpha", "beta", "gamma"]
	var best := ids[0]
	for id in ids:
		if float(scores[id]) > float(scores[best]):
			best = id
	return best

func _show_results(totals: Dictionary) -> void:
	results_panel = PanelContainer.new()
	results_panel.position = Vector2(180, 80)
	results_panel.size = Vector2(920, 600)
	root_ui.add_child(results_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	results_panel.add_child(box)
	var title := Label.new()
	title.text = "ELECTION NIGHT • FINAL RESULT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	var player_seats := int(totals.player)
	var winner := "National Reform" if player_seats >= int(totals.alpha) and player_seats >= int(totals.beta) and player_seats >= int(totals.gamma) else "RIVAL COALITION"
	text.text = "[center][font_size=22]%s[/font_size]\n\nNational Reform: %d seats\nDevelopment Front: %d seats\nPeople's Coalition: %d seats\nCivic Alliance: %d seats\n\n[font_size=18]Your result: %s[/font_size][/center]" % [winner, player_seats, int(totals.alpha), int(totals.beta), int(totals.gamma), "VICTORY" if winner == "National Reform" else "DEFEAT"]
	text.custom_minimum_size = Vector2(0, 300)
	box.add_child(text)
	var explain := Button.new()
	explain.text = "SHOW CLOSEST CONSTITUENCIES"
	explain.pressed.connect(_show_closest_results)
	box.add_child(explain)
	var close := Button.new()
	close.text = "CLOSE RESULTS"
	close.pressed.connect(func(): results_panel.queue_free())
	box.add_child(close)

func _show_closest_results() -> void:
	if results_panel == null:
		return
	var list: Array = results.duplicate(true)
	list.sort_custom(func(a, b): return _margin(a.scores) < _margin(b.scores))
	var lines := "CLOSEST RACES\n"
	for i in range(mini(10, list.size())):
		var r: Dictionary = list[i]
		lines += "%s — %s — margin %.2f%%\n" % [r.name, r.winner, _margin(r.scores) * 100.0]
	var popup := AcceptDialog.new()
	popup.title = "Election Explainability"
	popup.dialog_text = lines
	root_ui.add_child(popup)
	popup.popup_centered(Vector2(650, 500))

func _margin(scores: Dictionary) -> float:
	var values: Array[float] = []
	for id in ["player", "alpha", "beta", "gamma"]:
		values.append(float(scores[id]))
	values.sort()
	return values[-1] - values[-2]

func _seat_name(id: String) -> String:
	for seat in seats:
		if str(seat.get("unique_id", "")) == id:
			return str(seat.get("ls_seat_name", id))
	return id

func _save_game() -> void:
	if not campaign_started:
		_log("Start a campaign before saving.")
		return
	var data := {
		"version": 1,
		"seed": rng_seed,
		"week": week,
		"actions_used": actions_used,
		"money": money,
		"followers": followers,
		"risk": risk,
		"businesses": businesses,
		"selected_id": selected_id,
		"campaign_delta": campaign_delta,
		"ai_scores": ai_scores,
		"history": history
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		_log("Campaign saved.")

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_log("No saved campaign found.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		_log("Save file is invalid.")
		return
	var data: Dictionary = parsed
	week = int(data.get("week", 1))
	actions_used = int(data.get("actions_used", 0))
	money = int(data.get("money", STARTING_MONEY))
	followers = int(data.get("followers", STARTING_FOLLOWERS))
	risk = float(data.get("risk", 0.0))
	businesses = int(data.get("businesses", 0))
	selected_id = str(data.get("selected_id", ""))
	campaign_delta = data.get("campaign_delta", {}).duplicate(true)
	ai_scores = data.get("ai_scores", {}).duplicate(true)
	history = data.get("history", []).duplicate(true)
	campaign_started = true
	campaign_finished = false
	if start_overlay:
		start_overlay.queue_free()
	_update_ui()
	_log("Campaign loaded from Week %02d." % week)

func _update_ui() -> void:
	if week_label == null:
		return
	week_label.text = "WEEK %02d / %02d" % [week, WEEKS]
	money_label.text = "FUNDS ₹%s" % _money(money)
	follower_label.text = "FOLLOWERS %s" % _money(followers)
	risk_label.text = "RISK %.1f" % risk
	action_label.text = "ACTIONS %d / %d" % [actions_used, ACTIONS_PER_WEEK]
	if selected_id.is_empty():
		target_label.text = "TARGET: Select a constituency"
		support_label.text = "YOUR SUPPORT: —"
	else:
		target_label.text = "TARGET: %s" % selected_name
		var base: Dictionary = base_scores.get(selected_id, {})
		var support := float(base.get("player", 0.0)) + float(campaign_delta.get(selected_id, 0.0))
		support_label.text = "YOUR SUPPORT: %.1f%%" % (support * 100.0)
	for button in action_buttons:
		button.disabled = (not campaign_started) or campaign_finished or actions_used >= ACTIONS_PER_WEEK

func _log(message: String) -> void:
	if log_label == null:
		return
	var old := log_label.text
	var lines := old.split("\n")
	lines.append("• " + message)
	while lines.size() > 7:
		lines.pop_front()
	log_label.text = "\n".join(lines)

func _money(value: int) -> String:
	var s := str(value)
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count == 3 and i > 0:
			out = "," + out
			count = 0
	return out

func _hash_int(value: String) -> int:
	var digest := value.sha256_text().substr(0, 8)
	var result := 0
	for c in digest:
		var digit := "0123456789abcdef".find(c)
		if digit >= 0:
			result = result * 16 + digit
	return abs(result)
