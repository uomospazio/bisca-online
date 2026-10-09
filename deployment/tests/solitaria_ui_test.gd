extends SceneTree

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	menu.show_setup()
	var ui = menu.solitaria_ui
	assert(not menu.home_character.visible)
	assert(not menu.match_options.visible)
	assert(ui.logo.scale.length() < 0.001)
	assert(ui.font.multichannel_signed_distance_field)
	ui.settings.get_child(1).pressed.emit()
	assert(menu.match_options.lives.value == 2)
	ui.settings.get_child(2).pressed.emit()
	assert(menu.match_options.lives.value == 3)
	ui.settings.get_child(7).pressed.emit()
	assert(menu.bot_slider.value == 6)
	for bounds in [Rect2(40, 40, 1840, 1000), Rect2(100, 40, 2200, 900), Rect2(40, 40, 1200, 640)]:
		ui._layout(bounds)
		assert((ui.composition.position + ui.SOLO_SIZE * ui.composition.scale / 2).distance_to(bounds.get_center()) < 0.01)
		assert(ui.back_anchor.position == bounds.position)
		assert(ui.back_anchor.scale == ui.composition.scale)
	assert(ui.settings.size.is_equal_approx(ui.SETTINGS_SIZE))
	assert(ui.back.size == Vector2(108, 98))
	assert(ui.settings.get_child(1).size.is_equal_approx(Vector2(64, 64)))
	assert(ui.settings.get_child(1).get_child(0).size == Vector2(64, 70))
	await create_timer(1.4).timeout
	assert(ui.settings.scale.is_equal_approx(Vector2.ONE))
	ui.back.pressed.emit()
	assert(not menu.setup_page.visible)
	menu.show_setup()
	assert(menu.bot_slider.value == 7)
	print("PASS: solitaria UI, settings, centering, animation and back")
	menu.queue_free()
	await process_frame
	quit()
