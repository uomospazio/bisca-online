extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	menu._show_shop()
	await create_timer(0.5).timeout
	assert(menu.shop_page.content.get_child(0) is ColorRect)
	assert(menu.shop_page.content.get_child(0).get_child(0).texture.resource_path.ends_with("fullMarket.png"))
	var back: Control = menu.shop_page.fixed_controls[0]
	assert(back.position - Vector2(back.get_meta("safe_edge")) == Vector2(40, 40))
	var network = load("res://scenes/balatro/scripts/network_lobby.gd").new()
	menu.add_child(network)
	network.setup(menu)
	network.directory_timer.stop()
	var entries: Array = []
	for index in 10:
		entries.append({"id": str(index), "name": "Lobby di Giocatore %d" % index, "participants": 1, "capacity": 8, "private": index % 2 == 0})
	network._render_directory(entries)
	await process_frame
	await process_frame
	assert(network.directory_rows.get_child_count() == 10)
	assert(network.directory_panel.size == Vector2(1000, 616))
	assert(network.directory_rows.size.y > network.directory_panel.size.y)
	assert(not network.directory_panel.has_meta("safe_edge"))
	var network_back: Control = network.entry_buttons[-1]
	assert(network_back == network.entry_ui.back)
	assert(network_back.position.is_equal_approx(Vector2(40, 40)))
	print("PASS: fullMarket, safe-area back buttons, lobby card layout and scrolling")
	menu.queue_free()
	await process_frame
	quit()
