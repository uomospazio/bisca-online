extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	menu._show_network()
	await create_timer(0.7).timeout
	var reference: Button = menu.solo_buttons[0]
	var multiplayer_back: Button
	for child in menu.network_page.get_children():
		if child is Button and child.text == "INDIETRO":
			multiplayer_back = child
	assert(multiplayer_back != null)
	check(reference, multiplayer_back)
	menu.show_home()
	await create_timer(0.7).timeout
	menu._show_shop()
	await process_frame
	await process_frame
	check(reference, menu.shop_page.fixed_controls[0])
	menu.free()
	print("PASS: Indietro multiplayer/lobby e shop identici al singleplayer")
	quit()

func check(reference: Button, target: Button) -> void:
	assert(target.size.is_equal_approx(reference.size))
	assert(target.position.is_equal_approx(reference.position))
	assert(target.custom_minimum_size == reference.custom_minimum_size)
	assert(target.get_theme_stylebox("normal").corner_radius_top_left == reference.get_theme_stylebox("normal").corner_radius_top_left)
