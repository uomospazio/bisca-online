extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await create_timer(0.2).timeout
	for button in menu.home_intro_buttons:
		assert(button.scale.length() < 0.001, "Il layout non deve rendere visibili i pulsanti prima dell'intro: %s" % button.scale)
	await create_timer(0.25).timeout
	assert(menu.home_intro_buttons[0].scale.x > 0.0)
	assert(menu.home_intro_buttons[3].scale.length() < 0.001)
	await create_timer(0.8).timeout
	for button in menu.home_intro_buttons:
		assert(button.scale.is_equal_approx(Vector2.ONE))
		assert(button.mouse_filter == Control.MOUSE_FILTER_STOP)
	menu.queue_free()
	await process_frame
	print("PASS: layout preserves hidden buttons, staggered pop and final input")
	quit()
