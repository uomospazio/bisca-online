extends SceneTree

class SessionStub extends Node:
	var endpoint := "ws://test"
	var room_code := "ABCDEF"
	var token := "test-token"
	var commands: Array[Dictionary] = []
	var browsed := 0
	func browse_lobbies() -> void: browsed += 1
	func connect_room(_endpoint: String, command: Dictionary) -> void: commands.append(command)

func _initialize() -> void: _run.call_deferred()

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
	menu.network_page = lobby
	menu._show_network()
	assert(session.browsed == 1)
	assert(not menu.home_character.visible and not menu.second_character.visible)
	assert(not menu.title.visible and not menu.friends_subtitle.visible)
	assert(lobby.entry_ui.header.scale.length() < 0.001)
	assert(lobby.directory_panel.scale.length() < 0.001)
	assert(not lobby.entry_ui.characters.clip_contents)
	var entries: Array = [
		{"id": "public", "name": "Lobby di Uomospazio", "participants": 1, "capacity": 8, "private": false},
		{"id": "return", "name": "Lobby di Space", "participants": 2, "capacity": 8, "private": true, "rejoin": true},
		{"id": "private", "name": "Lobby di Franco", "participants": 1, "capacity": 8, "private": true}
	]
	lobby._render_directory(entries)
	await create_timer(0.8).timeout
	assert(not lobby.entry_ui.characters.clip_contents)
	assert(lobby.directory_rows.get_child_count() == 3)
	assert(lobby.directory_rows.get_child(0).get_meta("lobby_id") == "return")
	var first = lobby.directory_rows.get_child(0)
	first.get_child(first.get_child_count() - 1).pressed.emit()
	assert(session.commands[-1].op == "rejoin")
	lobby._join_directory(entries[0])
	assert(session.commands[-1].op == "join_public")
	lobby._join_directory(entries[2])
	assert(lobby.controls.visible and not lobby.entry.visible and lobby.entry_ui.back.visible)
	lobby._back()
	assert(lobby.entry.visible and not lobby.controls.visible)
	lobby.entry_buttons[0].pressed.emit()
	assert(session.commands[-1].op == "create" and not session.commands[-1].private)
	var ui = lobby.entry_ui
	assert(ui.header.size == Vector2(1000, 145))
	assert(lobby.directory_panel.size == Vector2(1000, 616))
	assert(ui.footer.size == Vector2(1000, 145))
	for character in ui.characters.get_children():
		var texture_size: Vector2 = character.texture.get_size()
		assert(is_equal_approx(character.size.x / character.size.y, texture_size.x / texture_size.y))
	for bounds in [Rect2(40, 40, 1840, 1000), Rect2(120, 50, 2292, 1050), Rect2(40, 40, 1200, 640)]:
		ui._layout(bounds)
		var center: Vector2 = ui.composition.position + ui.COMPOSITION_SIZE * ui.composition.scale / 2
		assert(center.is_equal_approx(bounds.get_center()))
		assert(ui.right.get_parent() == ui.characters.get_parent())
		assert(ui.right.position == ui.RIGHT_POSITION)
		assert(ui.right.scale == Vector2.ONE * ui.RIGHT_SCALE)
		assert((ui.composition.position + ui.COMPOSITION_SIZE * ui.composition.scale).x <= bounds.end.x + 0.1)
		var screen_center: Vector2 = ui.get_global_transform_with_canvas().affine_inverse() * (ui.get_viewport_rect().size * 0.5)
		var lobby_scale: float = preload("res://scenes/balatro/scripts/in_lobby_ui.gd").layout_scale(bounds, screen_center)
		assert(ui.back.size.is_equal_approx(Vector2(108, 98) * lobby_scale))
	await create_timer(0.6).timeout
	for character in ui.characters.get_children():
		assert(character.position.is_equal_approx(ui.character_targets[character]))
	assert(not ui.characters.clip_contents)
	assert(is_equal_approx(ui.character_sizes[ui.characters.get_child(0)].x, 580 * ui.CHARACTER_ZOOM))
	assert(is_equal_approx(ui.character_sizes[ui.characters.get_child(1)].x, 820 * ui.CHARACTER_ZOOM))
	assert(is_equal_approx(ui.characters.get_child(0).position.y, 315))
	assert(is_equal_approx(ui.characters.get_child(1).position.y, 130))
	assert(is_equal_approx(ui.characters.get_child(0).position.x + ui.characters.get_child(0).size.x / 2, 830))
	assert(is_equal_approx(ui.characters.get_child(1).position.x + ui.characters.get_child(1).size.x / 2, 400))
	ui._fit()
	for i in range(8):
		entries.append({"id": str(i), "name": "Lobby con nome molto lungo da contenere nello slot", "participants": 1, "capacity": 8, "private": false})
	lobby._render_directory(entries)
	await process_frame
	await process_frame
	assert(lobby.directory_rows.size.y > 444)
	assert(lobby.directory_rows.size.x <= 920)
	entries.resize(3)
	lobby._render_directory(entries)
	lobby.info.text = "Connessione al server in corso..."
	lobby._render_directory(entries)
	assert(not lobby.info.text.is_empty())
	lobby.info.text = ""
	if "--snapshot" in OS.get_cmdline_user_args():
		for child in menu.get_children():
			if child is CanvasItem and child != lobby: child.hide()
		var background := ColorRect.new()
		background.color = Color("1e1833")
		root.add_child(background)
		root.move_child(background, 0)
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ui.pop()
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-multiplayer-preview.png")
	print("PASS: multiplayer entry layout, scrolling, rejoin-first, create, public/private entry and back")
	menu.queue_free()
	session.queue_free()
	await process_frame
	quit()
