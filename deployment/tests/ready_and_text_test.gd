extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var net = root.get_node("NetworkSession")
	var room := {"people": [
		{"bot": false, "peer": 2, "ready": true},
		{"bot": false, "peer": 3, "ready": false},
		{"bot": true, "peer": 0}]}
	assert(not net._all_ready(room))
	room.people[1].ready = true
	assert(net._all_ready(room))
	room.people[1].peer = 0
	assert(not net._all_ready(room))
	room.people[1].peer = 3
	net._reset_ready(room)
	assert(not room.people[0].ready and not room.people[1].ready)
	assert(not net._all_ready({"people": [{"bot": true, "peer": 0}]}))
	var settings = root.get_node("GameSettings")
	var original: bool = settings.values.text_animations
	var subtitle = load("res://scenes/balatro/scripts/idle_subtitle.gd").new()
	var badge = load("res://scenes/balatro/scripts/player_badge.gd").new()
	root.add_child(subtitle)
	root.add_child(badge)
	subtitle.set_animated(true)
	settings.values.text_animations = false
	settings.changed.emit()
	assert(not subtitle.is_processing())
	assert(not subtitle.motion_enabled and not badge.text_motion_enabled)
	settings.values.text_animations = true
	settings.changed.emit()
	assert(subtitle.is_processing() and badge.text_motion_enabled)
	settings.values.text_animations = original
	settings.changed.emit()
	subtitle.free()
	badge.free()
	print("PASS: readiness, disconnected players, reset, bots, live text setting")
	quit()
