extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	assert(not menu.profile_panel.visible)
	menu.show_setup()
	await create_timer(0.5).timeout
	assert(menu.profile_panel.visible and not menu.title.visible)
	menu.name_input.text = "TEST"
	menu._refresh_single_profile()
	assert(menu.single_player_name.text == "TEST   · TU")
	assert(menu.match_options.position.y + menu.match_options.size.y < 950)
	menu._show_network()
	await create_timer(0.5).timeout
	assert(not menu.profile_panel.visible)
	menu.network_page.profile_room = "ABC123"
	menu.network_page._update({"stage": "lobby", "code": "ABC123", "you": 0,
		"people": [{"name": "TEST", "connected": true, "bot": false}], "options": {}})
	await create_timer(0.5).timeout
	assert(menu.profile_panel.is_visible_in_tree())
	assert(menu.network_page.players_box.get_child_count() == 8)
	menu.name_input.text = "NUOVO"
	var photo := Image.create(16, 16, false, Image.FORMAT_RGB8)
	photo.fill(Color.RED)
	menu.profile_texture = ImageTexture.create_from_image(photo)
	menu._refresh_single_profile()
	var own_card = menu.network_page.players_box.get_child(0)
	assert(own_card.get_meta("name_view").text == "NUOVO")
	assert(own_card.get_meta("avatar_view").texture == menu.profile_texture)
	menu.network_page._update_lobby_photos()
	assert(own_card.get_meta("avatar_view").texture == menu.profile_texture)
	assert(menu.network_page.lobby_options.position.y + menu.network_page.lobby_options.size.y < 950)
	menu.network_page.syncing_options = true
	menu.network_page.lobby_options.fill_bots.button_pressed = true
	await process_frame
	await process_frame
	assert(menu.network_page.lobby_options.position.y + menu.network_page.lobby_options.size.y < 950)
	menu.show_home()
	await create_timer(0.5).timeout
	assert(not menu.profile_panel.visible and menu.title.visible)
	print("PASS: home, singleplayer and lobby column layouts")
	quit()
