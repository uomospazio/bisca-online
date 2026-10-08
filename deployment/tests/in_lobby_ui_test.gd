extends SceneTree

class SessionStub extends Node:
	var latest: Dictionary
	var sent: Array[Dictionary] = []
	func send(command: Dictionary) -> void: sent.append(command)
	func avatar_for_slot(index: int) -> Texture2D:
		return preload("res://scenes/balatro/scripts/avatar_catalog.gd").TEXTURES[index]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	var lobby = load("res://scenes/balatro/scripts/network_lobby.gd").new()
	menu.add_child(lobby)
	lobby.setup(menu)
	lobby.directory_timer.stop()
	var session := SessionStub.new()
	root.add_child(session)
	lobby.net = session
	lobby.profile_room = "3E4714"
	var people: Array = []
	for player_name in ["Gambolosoco", "Space", "Uomospazio", "Giampiero", "Franco", "Luca"]:
		people.append({"name": player_name, "connected": true, "ready": false, "bot": false, "voice_id": ""})
	session.latest = {"stage": "lobby", "code": "3E4714", "you": 0, "people": people, "private": true, "bots": true, "bot_count": 2, "options": {"lives": 3, "starting_cards": 5, "turn_seconds": 30}}
	lobby._update(session.latest)
	await create_timer(0.9).timeout
	assert(lobby.players_box.get_child_count() == 8)
	assert(lobby.players_label.text == "6/8")
	assert(lobby.players_box.get_child(0).size.x == 564)
	assert(lobby.players_box.get_child(0).size.y == 80)
	assert(not lobby.entry_buttons[-1].visible)
	var ui = lobby.lobby_ui
	var visual_center: Vector2 = ui.content.position + ui.CONTENT_RECT.get_center() * ui.content.scale
	var viewport_center: Vector2 = ui.get_global_transform_with_canvas().affine_inverse() * (ui.get_viewport_rect().size / 2)
	assert(visual_center.is_equal_approx(viewport_center))
	assert(ui.blocks[-1].get_parent() == ui.back_anchor)
	assert(lobby.code_label.get_theme_font_size("font_size") == 56)
	assert(lobby.code_label.get_theme_font("font").multichannel_signed_distance_field)
	assert(ui.steppers[0].plus.get_child(0).size.x >= 64)
	assert(not ui.private_toggle.disabled)
	ui.steppers[0].plus.pressed.emit()
	assert(session.sent[-1].op == "settings" and session.sent[-1].lives == 4)
	ui.private_toggle.pressed.emit()
	assert(session.sent[-1] == {"op": "visibility", "private": false})
	lobby.start_button.pressed.emit()
	assert(session.sent[-1] == {"op": "ready", "ready": true})
	session.latest.people[0].ready = true
	lobby._update(session.latest)
	assert(lobby.start_button.get_theme_stylebox("normal").texture.resource_path.ends_with("annullaPronto.png"))
	session.latest.you = 1
	lobby._update(session.latest)
	assert(ui.private_toggle.disabled and ui.bots_toggle.disabled)
	for step in ui.steppers:
		assert(step.minus.disabled and step.plus.disabled)
	session.latest.you = 0
	lobby._update(session.latest)
	while session.latest.people.size() < 8:
		session.latest.people.append({"name": "Player", "connected": true, "ready": false, "bot": false, "voice_id": ""})
	lobby._update(session.latest)
	assert(ui.bots_toggle.disabled)
	assert(ui.steppers[2].minus.disabled and ui.steppers[2].plus.disabled)
	session.latest.people.resize(6)
	session.latest.people[0].ready = false
	lobby._update(session.latest)
	assert(not ui.bots_toggle.disabled)
	if "--snapshot" in OS.get_cmdline_user_args():
		for child in menu.get_children():
			if child is CanvasItem and child != lobby:
				child.hide()
		lobby.show()
		ui.pop()
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-in-lobby-preview.png")
	print("PASS: lobby artwork, eight slots, ready, host settings and guest restrictions")
	menu.queue_free()
	session.queue_free()
	await process_frame
	quit()
