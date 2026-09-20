extends SceneTree

func _initialize() -> void:
	var net = load("res://scenes/balatro/scripts/network_session.gd").new()
	var rules = load("res://scenes/balatro/scripts/match_rules.gd").new()
	rules.start(2, 12)
	var room := {"people": [
		{"token": "private-seat", "peer": 42, "bot": false},
		{"token": "", "peer": 0, "bot": true}], "rules": rules}
	# A stale socket no longer makes a valid credential ineligible.
	assert(net._rejoin_slot(room, "private-seat") == 0)
	assert(net._rejoin_slot(room, "") == -1)
	assert(net._rejoin_slot(room, "wrong-seat") == -1)
	room.people[0].peer = 0
	assert(net._rejoin_slot(room, "private-seat") == 0)
	var hand: Array = rules.players[0].hand.duplicate()
	var slot: int = net._rejoin_slot(room, "private-seat")
	room.people[slot].peer = 99
	assert(rules.players[0].hand == hand and rules.players[0].lives == 3)
	assert(not room.people[slot].bot)
	rules.current = 0
	rules.phase = "prediction"
	room.people[0].peer = 0
	net._set_turn(room)
	assert(room.deadline - Time.get_ticks_msec() <= 900)
	room.people[0].peer = 99
	net._set_turn(room)
	assert(room.deadline - Time.get_ticks_msec() > 29000)
	net.free()
	print("PASS: stale/offline seat recovery, invalid token rejection, human identity and state preserved")
	quit()
