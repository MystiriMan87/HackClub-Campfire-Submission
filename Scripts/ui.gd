extends CanvasLayer

@onready var score_label      = $ScorePanel/ScoreLabel
@onready var timer_label      = $TimerPanel/TimerLabel
@onready var fuel_bar         = $FuelPanel/FuelBar
@onready var fuel_label       = $FuelPanel/FuelLabel
@onready var depth_label      = $DepthPanel/DepthLabel
@onready var goal_label       = $GoalPanel/GoalLabel
@onready var game_over        = $GameOverPanel
@onready var final_label      = $GameOverPanel/VBoxContainer/FinalLabel
@onready var win_panel        = $WinPanel
@onready var win_label        = $WinPanel/VBoxContainer/WinLabel
@onready var leaderboard_list = $LeaderboardPanel/LeaderboardVBox/LeaderboardList
@onready var name_entry_panel = $NameEntryPanel
@onready var name_input       = $NameEntryPanel/VBoxContainer/NameInput
@onready var submit_button    = $NameEntryPanel/VBoxContainer/SubmitButton
@onready var menu_button      = $MenuButton

const GOAL_GEMS  = 5
const GOAL_GOLD  = 10
const MAX_FUEL   = 100.0

var score      = 0
var gems_found = 0
var gold_found = 0
var time_left  = 180.0
var fuel       = MAX_FUEL
var running    = false
var pending_entry = {}

func _ready():
	name_entry_panel.hide()
	submit_button.pressed.connect(_on_submit_pressed)
	name_input.text_submitted.connect(_on_name_submitted)
	menu_button.pressed.connect(_on_menu_button_pressed)
	_refresh_leaderboard_display()

	var nodes = {
		"score_label":      score_label,
		"timer_label":      timer_label,
		"fuel_bar":         fuel_bar,
		"fuel_label":       fuel_label,
		"depth_label":      depth_label,
		"goal_label":       goal_label,
		"game_over":        game_over,
		"final_label":      final_label,
		"win_panel":        win_panel,
		"win_label":        win_label,
		"leaderboard_list": leaderboard_list,
		"name_entry_panel": name_entry_panel,
		"name_input":       name_input,
		"submit_button":    submit_button,
		"menu_button":      menu_button
	}
	for node_name in nodes:
		if not nodes[node_name]:
			print("NULL NODE: ", node_name)

func start_timer():
	running = true
	game_over.hide()
	win_panel.hide()
	name_entry_panel.hide()
	_update_goal()

func _process(delta):
	if not running:
		return

	time_left -= delta
	fuel -= delta * 3.0

	if fuel > 60:
		fuel_bar.modulate = Color.GREEN
	elif fuel > 30:
		fuel_bar.modulate = Color.YELLOW
	else:
		fuel_bar.modulate = Color.RED

	fuel_bar.value = fuel
	fuel_label.text = "⛽ Fuel: %d%%" % int(fuel)

	var mins = int(time_left / 60)
	var secs = int(time_left) % 60
	timer_label.text = "⏱ %d:%02d" % [mins, secs]

	if time_left < 30:
		timer_label.modulate = Color.RED
	else:
		timer_label.modulate = Color.WHITE

	if time_left <= 0:
		_trigger_game_over("⏱ Time's Up!")
	elif fuel <= 0:
		_trigger_game_over("⛽ Out of Fuel!")

func add_score(amount: int, type: String):
	score += amount
	score_label.text = "💰 Score: %d" % score
	if type == "gold":
		gold_found += 1
	elif type == "gem":
		gems_found += 1
	_update_goal()
	if gems_found >= GOAL_GEMS and gold_found >= GOAL_GOLD:
		_trigger_win()

func add_fuel(amount: float):
	fuel = min(fuel + amount, MAX_FUEL)
	fuel_bar.value = fuel
	fuel_label.text = "⛽ Fuel: %d%%" % int(fuel)

func update_depth(depth_tiles: int):
	depth_label.text = "📏 Depth: %dm" % (depth_tiles * 2)

func _update_goal():
	goal_label.text = "🎯 Goal:\n💎 Gems: %d/%d\n🪙 Gold: %d/%d" % [
		gems_found, GOAL_GEMS, gold_found, GOAL_GOLD
	]

func _trigger_game_over(reason: String):
	if not running:
		return
	running = false
	if final_label:
		final_label.text = "%s\n\nFinal Score: %d\n💎 Gems: %d  🪙 Gold: %d" % [
			reason, score, gems_found, gold_found
		]
	game_over.show()
	_prompt_name_entry()

func _trigger_win():
	if not running:
		return
	running = false
	if win_label:
		win_label.text = "🏆 YOU WIN!\n\nScore: %d\nTime Left: %d:%02d" % [
			score, int(time_left / 60), int(time_left) % 60
		]
	win_panel.show()
	_prompt_name_entry()

func _prompt_name_entry():
	pending_entry = {
		"score": score,
		"time":  time_left,
		"gems":  gems_found,
		"gold":  gold_found
	}
	name_input.text = ""
	name_entry_panel.show()
	name_input.grab_focus()

func _on_submit_pressed():
	_on_name_submitted(name_input.text)

func _on_name_submitted(player_name: String):
	if player_name.strip_edges() == "":
		player_name = "Anonymous"
	pending_entry["name"] = player_name.strip_edges()
	print("Saving entry: ", pending_entry)
	_add_to_leaderboard(pending_entry)
	name_entry_panel.hide()

func _add_to_leaderboard(entry: Dictionary):
	GameData.add_entry(entry)
	print("Leaderboard size: ", GameData.leaderboard.size())
	_refresh_leaderboard_display()

func _refresh_leaderboard_display():
	if not leaderboard_list:
		print("leaderboard_list is NULL")
		return

	for child in leaderboard_list.get_children():
		child.queue_free()

	await get_tree().process_frame
	
	print("Leaderboard size when refreshing: ", GameData.leaderboard.size())
	print("Leaderboard contents: ", GameData.leaderboard)

	if GameData.leaderboard.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No runs yet!"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		leaderboard_list.add_child(empty_label)
		return

	for i in GameData.leaderboard.size():
		var entry = GameData.leaderboard[i]
		var row = Label.new()
		var medal: String
		if i == 0:
			medal = "🥇"
		elif i == 1:
			medal = "🥈"
		elif i == 2:
			medal = "🥉"
		else:
			medal = "%d." % (i + 1)

		var mins = int(entry["time"] / 60)
		var secs = int(entry["time"]) % 60
		row.text = "%s %s — %d pts (%d:%02d)" % [
			medal, entry["name"], entry["score"], mins, secs
		]
		if i == 0:
			row.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
		else:
			row.add_theme_color_override("font_color", Color.WHITE)
		row.add_theme_font_size_override("font_size", 13)
		leaderboard_list.add_child(row)

func reset_game():
	score      = 0
	gems_found = 0
	gold_found = 0
	time_left  = 180.0
	fuel       = MAX_FUEL
	score_label.text     = "💰 Score: 0"
	fuel_bar.value       = MAX_FUEL
	fuel_label.text      = "⛽ Fuel: 100%"
	timer_label.modulate = Color.WHITE
	start_timer()

func _on_restart_button_pressed():
	reset_game()
	get_parent().restart_game()

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
