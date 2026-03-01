extends Node

var leaderboard = []

func add_entry(entry: Dictionary):
	leaderboard.append(entry)
	leaderboard.sort_custom(func(a, b):
		if a["score"] != b["score"]:
			return a["score"] > b["score"]
		return a["time"] > b["time"]
	)
	if leaderboard.size() > 5:
		leaderboard.resize(5)
