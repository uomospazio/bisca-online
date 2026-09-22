extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var settings = root.get_node("GameSettings")
	settings.save_path = "/private/tmp/bisca-deck-test.cfg"
	settings.values.deck_back = 1
	var selector = load("res://scenes/balatro/scripts/deck_selector.gd").new()
	root.add_child(selector)
	assert(selector.selected == 1)
	for button in [selector.edit_button, selector.editing_controls[0], selector.editing_controls[1]]:
		assert(button.expand_icon)
		assert(button.get_theme_constant("icon_max_width") == 28)
		assert(button.size == Vector2(64, 64))
	selector._edit(true)
	selector._cycle(-1)
	assert(selector.selected == 12 and settings.values.deck_back == 1)
	selector._confirm()
	assert(settings.values.deck_back == 12 and selector.edit_button.visible)
	for control in selector.editing_controls:
		assert(not control.visible)
	settings.load_preferences()
	assert(settings.values.deck_back == 12)
	selector._cycle(1)
	assert(selector.selected == 1)
	for i in range(1, 13):
		assert(settings.back_texture(i) != null)
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	assert(menu.deck_selector.visible)
	assert(menu.name_input.get_parent() == menu.home_page)
	assert(menu.profile_button.get_node("CameraIcon").visible)
	var camera = menu.profile_button.get_node("CameraIcon")
	assert(camera.size == Vector2(96, 96))
	assert(camera.position + camera.size / 2 == menu.profile_button.size / 2)
	assert(menu.name_input.position.y < menu.profile_button.position.y + menu.profile_button.size.y)
	assert(menu.name_input.position.y > menu.profile_button.position.y + menu.profile_button.size.y / 2)
	menu.name_input.text = "Test"
	assert(menu.chosen_name() == "TEST")
	menu.show_setup()
	assert(not menu.deck_selector.visible)
	menu._show_network()
	assert(menu.name_input.get_parent() == menu.home_page)
	assert(menu.network_page.profile_picker == menu.profile_picker)
	var lobby = menu.network_page
	lobby.profile_room = "TEST12"
	var people: Array = []
	for i in range(8):
		people.append({"name": "PLAYER%d" % i, "connected": true, "bot": false, "voice_id": "voice%d" % i})
	var state := {"stage": "lobby", "code": "TEST12", "you": 1, "people": people, "options": {"lives": 6, "starting_cards": 4}, "bots": true, "bot_count": 3}
	lobby._update(state)
	assert(lobby.players_box.get_child_count() == 8)
	assert(lobby.lobby_options.lives.value == 6)
	assert(not lobby.lobby_options.lives.editable)
	assert(lobby.lobby_options.fill_bots.disabled)
	assert(lobby.start_button.disabled)
	state.you = 0
	lobby._update(state)
	assert(lobby.lobby_options.lives.editable and not lobby.start_button.disabled)
	assert(lobby.players_box.get_child_count() == 8)
	print("PASS: 12 backs, wraparound, confirmation, persistence and home-only selector")
	quit()
