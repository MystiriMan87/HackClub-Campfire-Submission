extends Control

@onready var leaderboard_list = $LeaderboardList 

func _ready():
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$QuitButton.pressed.connect(_on_quit_button_pressed)
	_show_leaderboard()


func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

func _show_leaderboard():
	if not leaderboard_list:
		return
	if GameData.leaderboard.is_empty():
		return

	for i in GameData.leaderboard.size():
		var entry = GameData.leaderboard[i]
		var label = Label.new()
		var medal: String
		if i == 0:
			medal = "🥇"
		elif i == 1:
			medal = "🥈"
		elif i == 2:
			medal = "🥉"
		else:
			medal = "%d." % (i + 1)

		label.text = "%s %s — %d pts" % [medal, entry["name"], entry["score"]]
		leaderboard_list.add_child(label)
