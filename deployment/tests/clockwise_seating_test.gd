extends SceneTree

func _initialize() -> void:
	var controller = load("res://scenes/balatro/scripts/match_controller.gd").new()
	var table = load("res://scenes/balatro/scripts/play_area.gd").new()
	table.size = Vector2(1600, 800)
	var card := Control.new()
	card.size = Vector2(100, 150)
	# Singleplayer: gli ID dei bot non coincidono piu' con i posti dopo lo shuffle.
	controller.online = false
	for count in range(2, 9):
		for attempt in range(100):
			var seating: Array = range(count)
			seating.shuffle()
			controller.rules.seat_order.assign(seating)
			assert(controller._visual_seat_for_player(0) == 0)
			for player in range(1, count):
				var expected := posmod(seating.find(player) - seating.find(0), count)
				card.set_meta("seat_id", controller._visual_seat_for_player(player))
				assert(table.landing_position(card) == table.size / 2 + table.LANDINGS[expected] - card.size / 2)
				assert(table.landing_rotation(card) == table.READABLE_ANGLES[expected])
	card.free()
	table.free()
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
