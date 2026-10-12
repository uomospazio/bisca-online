extends SceneTree

class Host extends Control:
	var online := false
	var menu := Control.new()
	var loading_screen := {"busy": false}
	var hand := {"cards": []}
	func _ready() -> void:
		add_child(menu)
		menu.hide()

func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(1800, 900)
	var settings := root.get_node("GameSettings")
	settings.save_path = "/tmp/bisca-in-game-settings-test.cfg"
	var host := Host.new()
	root.add_child(host)
	var pause = preload("res://scenes/balatro/scripts/pause_menu.gd").new()
	host.add_child(pause)
	pause.setup(host)
	pause.open()
	assert(paused and pause.visible and pause.restart_button.visible)
	var ui = pause.actions
	ui.sliders.main.value = 67
	assert(settings.values.main == 67 and ui.numbers.main.text == "67")
	var before: bool = settings.values.show_thrown_objects
	ui.toggles.show_thrown_objects.pressed.emit()
	assert(settings.values.show_thrown_objects != before)
	if "--snapshot" in OS.get_cmdline_user_args(): await snapshot("solo")
	pause._confirm_leave(true)
	assert(paused and not ui.visible and pause.confirmation.title == "RIAVVIARE LA PARTITA?")
	assert(pause.confirmation.panel.has_meta("generic_ui_material"))
	await process_frame
	await process_frame
	pause.confirmation.get_cancel_button().pressed.emit()
	assert(paused and ui.visible and pause.confirmation == null)
	pause.continue_button.pressed.emit()
	assert(not paused and not pause.visible)
	host.online = true
	var voice := root.get_node("VoiceChat")
	voice._on_network_updated({"code": "TEST", "you": 0, "people": [
		{"name": "ME", "voice_id": "me", "connected": true},
		{"name": "UOMOSPAZIO", "voice_id": "other", "connected": true},
		{"name": "BOT", "voice_id": "bot", "bot": true},
		{"name": "LEFT", "voice_id": "left", "connected": false}]})
	pause.open()
	assert(not paused and not pause.restart_button.visible)
	assert(ui.participant_sliders.keys() == ["other"])
	ui.participant_sliders.other.value = 35
	assert(voice.player_volume("other") == 35 and ui.participant_numbers.other.text == "35")
	settings.set_value("microphone_enabled", false)
	voice.muted = true
	ui.toggles.microphone.pressed.emit()
	assert(settings.values.microphone_enabled and not voice.muted and not voice.enabled)
	ui.toggles.microphone.pressed.emit()
	assert(not settings.values.microphone_enabled and voice.muted)
	voice.enabled = true
	ui.toggles.voice.pressed.emit()
	assert(not voice.enabled and not settings.values.microphone_enabled)
	if "--snapshot" in OS.get_cmdline_user_args(): await snapshot("multi")
	assert(ui.toggles.voice.position.y == 60)
	assert(ui.continue_button.position.y == 630)
	pause._confirm_leave(false)
	assert(not paused and pause.confirmation.ok_button_text == "ABBANDONA")
	await process_frame
	await process_frame
	pause.confirmation.get_cancel_button().pressed.emit()
	assert(ui.visible and pause.confirmation == null)
	pause.close()
	host.queue_free()
	await process_frame
	assert(not paused)
	print("PASS: solo pause/resume, multiplayer live, volumes, roster filtering, independent microphone and chat toggles")
	quit()

func snapshot(label: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/bisca-game-settings-" + label + ".png")
