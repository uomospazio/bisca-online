extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	create_timer(20).timeout.connect(func(): quit(1))
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	var lobby = load("res://scenes/balatro/scripts/network_lobby.gd").new()
	menu.network_page = lobby
	menu.add_child(lobby)
	lobby.setup(menu)
	lobby.directory_timer.stop()
	var net := root.get_node("NetworkSession")
	net.room_code = "TEST01"
	net.latest = {"stage":"lobby", "code":"TEST01", "you":0,
		"people":[{"name":"TEST","connected":true,"bot":false,"ready":false,"voice_id":"self"}],
		"private":true, "bots":true, "bot_count":7,
		"options":{"lives":3,"starting_cards":5,"turn_seconds":30}}
	lobby.profile_room = "TEST01"
	lobby._update(net.latest)
	menu._switch_page(lobby)
	await create_timer(0.8).timeout
	var voice := root.get_node("VoiceChat")
	voice.current_room = "TEST01"
	voice.enabled = true
	voice.muted = false
	lobby.lobby_ui.customization_anchor.get_node("LobbyPersonalization").pressed.emit()
	await process_frame
	assert(menu.active_page == menu.personalization_page)
	assert(net.room_code == "TEST01")
	assert(voice.current_room == "TEST01" and voice.enabled and not voice.muted)
	# Update the in-match name without persisting test data to the user's profile.
	menu.name_input.text = "UPDATED"
	menu.personalization_page.back_button.pressed.emit()
	await create_timer(0.8).timeout
	assert(menu.active_page == lobby and lobby.visible)
	var ui = lobby.lobby_ui
	var actual_center: Vector2 = ui.content.get_global_transform_with_canvas() * ui.CONTENT_RECT.get_center()
	assert(actual_center.distance_to(root.get_visible_rect().size / 2) < 2.0,
		"Lobby must be centered immediately after return, without resizing")
	assert(not menu.personalization_page.visible)
	assert(not menu.profile_panel.visible)
	assert(lobby.players_box.get_child(0).get_meta("name_view").text == "UPDATED")
	assert(net.room_code == "TEST01")
	assert(voice.current_room == "TEST01" and voice.enabled and not voice.muted)
	menu._show_lobby_personalization()
	net.latest.stage = "playing"
	lobby._update(net.latest)
	await create_timer(0.8).timeout
	assert(menu.personalization_lobby_code.is_empty())
	assert(not menu.personalization_page.visible)
	# A disconnected room cannot be revisited by the back button.
	net.latest.stage = "lobby"
	lobby._update(net.latest)
	menu._switch_page(lobby)
	menu._show_lobby_personalization()
	net.room_code = ""
	net.latest = {}
	menu._leave_personalization()
	assert(menu.active_page == menu.home_page)
	print("PASS: lobby customization/back, name refresh, voice retained, match-start and lost-room guards")
	quit()
