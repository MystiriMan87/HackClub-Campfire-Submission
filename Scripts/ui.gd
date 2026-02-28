extends CanvasLayer

@onready var score_label   = $ScorePanel/ScoreLabel
@onready var timer_label   = $TimerPanel/TimerLabel
@onready var fuel_bar      = $FuelPanel/FuelBar
@onready var fuel_label    = $FuelPanel/FuelLabel
@onready var depth_label   = $DepthPanel/DepthLabel
@onready var goal_label    = $GoalPanel/GoalLabel
@onready var game_over     = $GameOverPanel
@onready var final_label   = $GameOverPanel/FinalLabel
@onready var win_panel     = $WinPanel
@onready var win_label     = $WinPanel/WinLabel

const GOAL_GEMS  = 5
const GOAL_GOLD  = 10
const MAX_FUEL   = 100.0

var score      = 0
var gems_found = 0
var gold_found = 0
var time_left  = 180.0
var fuel       = MAX_FUEL
var running    = false

func start_timer():
	running = true
	game_over.hide()
	win_panel.hide()
	_update_goal()

func _process(delta):
	if not running: return

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

func _update_goal():
	goal_label.text = "🎯 Goal:\n💎 Gems: %d/%d\n🪙 Gold: %d/%d" % [
		gems_found, GOAL_GEMS,
		gold_found, GOAL_GOLD
	]

func update_depth(depth_tiles: int):
	depth_label.text = "📏 Depth: %dm" % (depth_tiles * 2)

func _trigger_game_over(reason: String):
	running = false
	game_over.show()
	final_label.text = "%s\n\nFinal Score: %d\n💎 Gems: %d  🪙 Gold: %d" % [
		reason, score, gems_found, gold_found
	]

func _trigger_win():
	running = false
	win_panel.show()
	win_label.text = "🏆 YOU WIN!\n\nScore: %d\nTime Left: %d:%02d" % [
		score, int(time_left / 60), int(time_left) % 60
	]
	
func add_fuel(amount: float):
	fuel = min(fuel + amount, MAX_FUEL)  
	fuel_bar.value = fuel
	fuel_label.text = "⛽ Fuel: %d%%" % int(fuel)
