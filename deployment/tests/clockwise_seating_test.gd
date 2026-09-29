extends SceneTree

func _initialize() -> void:
	var controller = load("res://scenes/balatro/scripts/match_controller.gd").new()
	controller.online = true
	for count in range(2,9):
		controller.player_count = count
		for attempt in range(100):
			var seating: Array = range(count)
			seating.shuffle()
			controller.online_match.state = {"seat_order":seating}
			for viewer in range(count):
				controller.online_match.local_id = viewer
				assert(controller._visual_seat_for_player(0) == 0)
				for index in range(count):
					var server_id: int = seating[index]
					var next_id: int = seating[(index+1)%count]
					var local_id: int = controller.online_match.seat(server_id,count)
					var next_local: int = controller.online_match.seat(next_id,count)
					assert(controller._visual_seat_for_player(next_local) == (controller._visual_seat_for_player(local_id)+1)%count)
	controller.free()
	print("PASS: giro orario per 2-8 giocatori, 100 ordini casuali e tutte le visuali")
	quit()
