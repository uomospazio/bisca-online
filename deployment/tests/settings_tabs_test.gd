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
	assert(page.chapters.get_child_count() == 4)
	assert(page.chapters.get_child(0).name == "ACCOUNT")
	assert(page.chapters.get_child(1).name == "GRAFICA")
	assert(page.toggles.push_notifications.get_parent().get_parent().get_parent() == page.chapters.get_child(0))
	assert(page.toggles.show_thrown_objects.get_parent().get_parent().get_parent() == page.chapters.get_child(1))
	assert(page.content_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(page.page_title.text == "SETTINGS")
	assert(page.sliders.size() == 2)
	assert(not page.toggles.has("tooltips"))
	assert(settings.values.show_thrown_objects)
	assert(page.artwork_ui != null and not page.settings_panel.visible)
	var session := root.get_node("AccountSession")
	session._read_user({"identities": [{"provider": "google", "identity_data": {"email": "test@example.com"}}]})
	page.artwork_ui.sync()
	assert(page.artwork_ui.provider_overlays.google.visible)
	assert(not page.artwork_ui.provider_overlays.email.visible)
	assert(not page.artwork_ui.provider_overlays.apple.visible)
	page.artwork_ui._open_provider("google")
	var connected = page.get_child(page.get_child_count() - 1)
	assert(connected.mode == "connected_google")
	connected.queue_free()
	page.artwork_ui._open_provider("apple")
	var sign_in = page.get_child(page.get_child_count() - 1)
	assert(sign_in.mode == "apple" and sign_in.provider_intent == "login")
	sign_in.queue_free()
	page.artwork_ui._account("new_guest")
	var new_account = page.get_child(page.get_child_count() - 1)
	assert(new_account.rows.get_child(0).text == "CREA NUOVO ACCOUNT")
	assert(new_account.buttons[0].text == "CONFERMA")
	assert(new_account.buttons.back().get_meta("generic_ui_material").get_shader_parameter("fill_top") == Color("88302c"))
	new_account.queue_free()
	session._read_user({})
	page.artwork_ui.toggle_buttons.show_thrown_objects.pressed.emit()
	assert(not settings.values.show_thrown_objects)
	page.artwork_ui.toggle_buttons.show_thrown_objects.pressed.emit()
	assert(settings.values.show_thrown_objects)
	page.artwork_ui.volume_sliders.main.value = 61
	assert(settings.values.main == 61)
	assert(page.artwork_ui.volume_numbers.main.text == "61")
	page.artwork_ui.language_choice.pressed.emit()
	assert(settings.values.language == "en")
	settings.set_value("language", "en")
	assert(page.chapters.get_child(1).get_child(0).get_child(0).text == "GRAPHICS")
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
	assert(page.chapters.get_child(1).get_child(0).get_child(0).text == "GRAFICA")
	if "--snapshot" in OS.get_cmdline_user_args():
		var bg := ColorRect.new()
		bg.color = Color("1e1833")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
		root.move_child(bg, 0)
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-settings-preview.png")
	page.queue_free()
	host.queue_free()
	await process_frame
	# Exercise the real navigation: a stub cannot catch fitting during a slide.
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	for visit in 2:
		menu._show_settings()
		await create_timer(0.7).timeout
		var ui = menu.settings_page.artwork_ui
		var before: Vector2 = ui.composition.get_global_transform_with_canvas() * (ui.DESIGN_SIZE / 2)
		assert(before.distance_to(root.get_visible_rect().get_center()) < 1.0)
		ui._fit()
		var after: Vector2 = ui.composition.get_global_transform_with_canvas() * (ui.DESIGN_SIZE / 2)
		assert(before.distance_to(after) < 0.1)
		menu.show_home()
		await process_frame
	menu.queue_free()
	await process_frame
	print("PASS: tabs, translation, persistence, reset, push-to-talk, hidden throws")
	quit()
