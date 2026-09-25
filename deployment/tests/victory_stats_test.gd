extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var rules = preload("res://scenes/balatro/scripts/match_rules.gd").new()
	rules.start(3, 123)
	var expected := [{"exact": 0, "rounds": 0, "taken": 0}, {"exact": 0, "rounds": 0, "taken": 0}, {"exact": 0, "rounds": 0, "taken": 0}]
	while rules.phase != "finished":
		if rules.phase == "prediction":
			rules.predict(rules.current, rules.legal_bids(rules.current)[0])
		elif rules.phase == "play":
			rules.play(rules.current, 0)
		elif rules.phase == "trick_complete":
			rules.advance_trick()
			if rules.phase in ["round_complete", "finished"]:
				for result in rules.round_result:
					var tally: Dictionary = expected[result.player]
					tally.exact += 1 if result.bid == result.taken else 0
					tally.rounds += 1
					tally.taken += result.taken
		elif rules.phase == "round_complete":
			rules.begin_round()
	for p in rules.view_for(0).players:
		assert(p.exact_predictions == expected[p.id].exact)
		assert(p.rounds_played == expected[p.id].rounds)
		assert(p.total_taken == expected[p.id].taken)
	var overlay = preload("res://scenes/balatro/scripts/game_overlay.gd").new()
	root.add_child(overlay)
	overlay.show_victory("GIOCATORE", null, rules.players[rules.winner])
	await process_frame
	await process_frame
	assert(overlay.victory_details.visible)
	assert(overlay.panel.size.y < 1080, "Victory panel exceeds the game height")
	rules.start(3, 123)
	assert(rules.players[0].rounds_played == 0)
	assert(rules.players[0].total_taken == 0)
	print("PASS: accumulated statistics, network view, restart reset and victory layout")
	quit()
