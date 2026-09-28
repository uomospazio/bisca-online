extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	assert(not menu.profile_panel.visible)
	menu.show_setup()
	await create_timer(0.8).timeout
	assert(not menu.profile_panel.visible and menu.title.visible)
	assert(not menu.home_persistent_ui.visible)
	assert(menu.home_character.position.is_equal_approx(menu.SOLO_CHARACTER_POSITION))
	assert(menu.title.position == menu.SOLO_TITLE_POSITION)
	assert(menu.friends_subtitle.text == "SOLITARIA")
	assert(menu.title.scale.is_equal_approx(Vector2.ONE))
	menu.name_input.text = "TEST"
	menu._refresh_single_profile()
	assert(menu.single_player_name.text == "TEST   · TU")
	assert(menu.match_options.position.y + menu.match_options.size.y < 950)
	menu._show_network()
	await create_timer(0.5).timeout
	assert(not menu.profile_panel.visible)
	assert(not menu.home_persistent_ui.visible)
	assert(menu.title.position == menu.SOLO_TITLE_POSITION)
	assert(menu.friends_subtitle.text == "WITH YOUR FRIENDS")
	assert(menu.profile_button.get_parent() == menu.home_persistent_ui)
	assert(menu.name_input.get_parent() == menu.home_persistent_ui)
	assert(menu.deck_selector.get_parent() == menu.home_persistent_ui)
	menu.network_page.profile_room = "ABC123"
	var lobby_state := {"stage": "lobby", "code": "ABC123", "you": 0,
		"people": [{"name": "TEST", "connected": true, "bot": false}], "options": {}}
	menu.network_page._update(lobby_state)
	await create_timer(0.5).timeout
	assert(not menu.home_persistent_ui.visible)
	assert(menu.profile_panel.is_visible_in_tree())
	assert(menu.network_page.players_box.get_child_count() == 8)
	menu.name_input.text = "NUOVO"
	var photo := Image.create(16, 16, false, Image.FORMAT_RGB8)
	photo.fill(Color.RED)
	menu.profile_texture = ImageTexture.create_from_image(photo)
	menu._refresh_single_profile()
	var own_card = menu.network_page.players_box.get_child(0)
	var original_id: int = own_card.get_instance_id()
	lobby_state.options = {"lives": 4}
	menu.network_page._update(lobby_state)
	assert(menu.network_page.players_box.get_child(0).get_instance_id() == original_id, "Settings must reuse player cards")
	assert(menu.network_page.lobby_options.lives.value == 4)
	lobby_state.people[0]["voice_active"] = true
	menu.network_page._update(lobby_state)
	own_card = menu.network_page.players_box.get_child(0)
	assert(own_card.get_instance_id() != original_id, "Changed player state must update cards")
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
