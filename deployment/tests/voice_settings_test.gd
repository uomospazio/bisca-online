extends SceneTree

class MenuStub extends Control:
	func show_home() -> void:
		pass
	func _button(parent: Node, caption: String, callback: Callable) -> Button:
		var button := Button.new()
		button.text = caption
		button.pressed.connect(callback)
		parent.add_child(button)
		return button

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var network = load("res://scenes/balatro/scripts/network_session.gd").new()
	assert(network._valid_voice_payload({"type": "ready", "epoch": "abc"}))
	assert(network._valid_voice_payload({"type": "description", "epoch": "abc", "description": {"type": "offer", "sdp": "v=0"}}))
	assert(not network._valid_voice_payload({"type": "description", "epoch": "abc", "description": null}))
	assert(not network._valid_voice_payload({"type": "description", "epoch": "abc", "description": {"type": "offer", "sdp": "x".repeat(65537)}}))
	assert(not network._valid_voice_payload({"type": "candidate", "epoch": "abc", "candidate": {"candidate": "x".repeat(4097)}}))
	assert(not network._valid_voice_payload({"type": "ready", "epoch": 12}))
	network.free()
	var voice = root.get_node("VoiceChat")
	var people: Array = []
	for slot in range(8):
		people.append({"name": "PLAYER %d" % slot, "voice_id": "id%d" % slot, "bot": false, "connected": true})
	voice._on_network_updated({"code": "TEST", "you": 0, "people": people})
	var menu := MenuStub.new()
	root.add_child(menu)
	var page = load("res://scenes/balatro/scripts/settings_page.gd").new()
	root.add_child(page)
	page.setup(menu, menu.show_home, true)
	await process_frame
	assert(page.voice_rows.get_child_count() == 7)
	var slider: HSlider = page.voice_rows.get_child(0).get_child(1)
	slider.value = 25
	assert(voice.player_volume("id1") == 25)
	voice._on_network_updated({"code": "TEST", "you": 0, "people": people})
	assert(voice.player_volume("id1") == 25)
	people[2].bot = true
	voice._on_network_updated({"code": "TEST", "you": 0, "people": people})
	assert(page.voice_rows.get_child_count() == 6)
	voice.leave()
	assert(voice.people.is_empty() and voice.volumes.is_empty())
	print("PASS: validation, 7 player sliders, individual volume, lobby persistence, bot exclusion, cleanup")
	quit()
