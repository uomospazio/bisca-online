extends SceneTree

class NativeBridge extends RefCounted:
	var calls: Array = []
	var events: Array = []
	func invoke(method: String, arguments: String) -> void:
		calls.append([method, JSON.parse_string(arguments)])
	func drain() -> String:
		var result := JSON.stringify(events)
		events.clear()
		return result

class SessionStub extends Node:
	var latest: Dictionary
	func send(_command: Dictionary) -> void: pass
	func avatar_for_slot(_index: int) -> Texture2D: return null

func _initialize() -> void: run.call_deferred()

func run() -> void:
	create_timer(15).timeout.connect(func():
		push_error("Lobby voice regression timed out")
		quit(1)
	)
	var voice := root.get_node("VoiceChat")
	voice.set_process(false)
	var native := NativeBridge.new()
	voice.native_bridge = native
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	var lobby = load("res://scenes/balatro/scripts/network_lobby.gd").new()
	menu.add_child(lobby)
	lobby.setup(menu)
	lobby.directory_timer.stop()
	var session := SessionStub.new()
	root.add_child(session)
	lobby.net = session
	lobby.profile_room = "TEST01"
	session.latest = {"stage": "lobby", "code": "TEST01", "you": 0,
		"people": [{"name": "SELF", "connected": true, "ready": false, "bot": false, "voice_id": "self", "voice_active": false}],
		"private": true, "bots": false, "bot_count": 0, "options": {"lives": 3, "starting_cards": 5, "turn_seconds": 30}}
	voice._on_network_updated(session.latest)
	lobby._update(session.latest)
	await process_frame
	var row: Control = lobby.players_box.get_child(0)
	var speaker: Button = row.get_meta("voice_button")
	speaker.pressed.emit()
	await process_frame
	assert(voice.pending and native.calls.back()[0] == "start")
	native.events.append({"op": "status", "text": "Connected", "enabled": true, "muted": false, "pending": false})
	voice._process(0.0)
	assert(voice.enabled and not voice.pending)
	var original_icon: TextureRect = row.get_meta("voice_icon")
	var first_tween: Tween = original_icon.get_meta("voice_tween")
	# Repeated status signals must not restart an in-flight icon transition.
	voice.changed.emit()
	assert(original_icon.get_meta("voice_tween") == first_tween)
	# A voice-only server snapshot must preserve the row and its active button.
	await create_timer(0.04).timeout
	session.latest.people[0].voice_active = true
	voice._on_network_updated(session.latest)
	lobby._update(session.latest)
	assert(is_instance_valid(row) and lobby.players_box.get_child(0) == row)
	await create_timer(0.35).timeout
	row = lobby.players_box.get_child(0)
	var icon: TextureRect = row.get_meta("voice_icon")
	assert(icon.get_meta("current_icon") == "mic-on")
	assert(icon.scale.is_equal_approx(Vector2.ONE))
	row.get_meta("voice_button").pressed.emit()
	await process_frame
	assert(not voice.enabled and not voice.pending)
	await create_timer(0.35).timeout
	assert(icon.get_meta("current_icon") == "mic-off")
	# Rapid reversals must cancel the pending change, including before texture swap.
	lobby._set_voice_icon_tween(icon, "mic-on")
	lobby._set_voice_icon_tween(icon, "mic-off")
	await create_timer(0.35).timeout
	assert(icon.get_meta("current_icon") == "mic-off" and icon.scale == Vector2.ONE)
	# A real roster change may still destroy a row: its tween must die with it.
	lobby._set_voice_icon_tween(icon, "mic-on")
	var removed_tween: Tween = icon.get_meta("voice_tween")
	session.latest.people[0].ready = true
	lobby._update(session.latest)
	await create_timer(0.35).timeout
	assert(not is_instance_valid(icon) and not removed_tween.is_valid())
	assert(lobby.players_box.get_child(0).get_meta("voice_icon").get_meta("current_icon") == "mic-off")
	voice.native_bridge = null
	menu.queue_free()
	session.queue_free()
	await process_frame
	print("PASS: lobby microphone activation, stable voice-only snapshots, repeated status, rapid reversal, roster rebuild and stop")
	quit()
