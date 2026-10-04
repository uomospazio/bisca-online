extends SceneTree

class Host extends Control:
	func show_home() -> void: pass
	func _notification_dot(button: Control) -> Panel:
		return preload("res://scenes/balatro/scripts/main_menu.gd")._notification_dot(button)
	func _button(parent: Node, caption: String, action: Callable) -> Button:
		var button := Button.new()
		button.text = caption
		button.pressed.connect(action)
		parent.add_child(button)
		return button

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var settings = root.get_node("GameSettings")
	settings.save_path = "/tmp/bisca-settings-tabs-test.cfg"
	settings.values = settings.DEFAULTS.duplicate(true)
	var host := Host.new()
	root.add_child(host)
	var page = load("res://scenes/balatro/scripts/settings_page.gd").new()
	root.add_child(page)
	page.setup(host)
	await process_frame
	assert(page.tabs.get_tab_count() == 5)
	assert(page.sliders.size() == 2)
	assert(not page.toggles.has("tooltips"))
	assert(settings.values.show_thrown_objects)
	settings.set_value("language", "en")
	assert(page.tabs.get_tab_title(2) == "GRAPHICS")
	assert(page.reset_dialog.title == "RESET SETTINGS")
	settings.set_value("show_thrown_objects", false)
	settings.set_value("push_to_talk", true)
	settings.save_preferences()
	settings.values = settings.DEFAULTS.duplicate(true)
	settings.load_preferences()
	assert(settings.values.language == "en" and settings.values.push_to_talk)
	assert(not settings.values.show_thrown_objects)
	var voice = root.get_node("VoiceChat")
	voice.set_talk_held(false)
	assert(voice.muted)
	voice.set_talk_held(true)
	assert(not voice.muted)
	settings.set_value("microphone_enabled", false)
	voice.set_talk_held(true)
	assert(voice.muted)
	var throws = load("res://scenes/balatro/scripts/throw_objects.gd").new()
	root.add_child(throws)
	throws._launch(0, 1)
	assert(throws.get_child_count() == 0)
	throws.queue_free()
	page.reset_dialog.confirmed.emit()
	assert(settings.values.language == "it" and settings.values.show_thrown_objects)
	assert(page.tabs.get_tab_title(2) == "GRAFICA")
	page.queue_free()
	host.queue_free()
	await process_frame
	print("PASS: tabs, translation, persistence, reset, push-to-talk, hidden throws")
	quit()
