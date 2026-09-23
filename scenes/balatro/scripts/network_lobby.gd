extends Control

var menu: Control
var net: Node
var address: LineEdit
var code: LineEdit
var match_options: PanelContainer
var info: Label
var start_button: Button
var controls: VBoxContainer
var session_controls: Control
var lobby_options: PanelContainer
var copied_code := ""
var syncing_options := false
var is_host := false
var players_box: VBoxContainer
var code_button: Button
var code_label: Label
var copy_icon: TextureRect
var entry: VBoxContainer
var create_button: Button
var join_button: Button
var rejoin_button: Button
var profile_picker: Node
var profile_room := ""

func setup(owner_menu: Control) -> void:
	menu = owner_menu
	net = get_node("/root/NetworkSession")
	profile_picker = menu.profile_picker
	profile_picker.selected.connect(func(avatar):
		if net.room_code == profile_room and not profile_room.is_empty():
			net.send({"op": "profile", "avatar": avatar})
	)
	net.avatars_changed.connect(_update_lobby_photos)
	net.connection_lost.connect(profile_picker.close)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	entry = VBoxContainer.new()
	add_child(entry)
	entry.position = Vector2(640, 530)
	entry.size = Vector2(640, 200)
	entry.add_theme_constant_override("separation", 24)
	var choices := HBoxContainer.new()
	entry.add_child(choices)
	choices.add_theme_constant_override("separation", 24)
	var create: Button = menu._button(choices, "CREA LOBBY", func(): net.connect_room(net.endpoint, {"op": "create", "name": menu.chosen_name(), "capacity": 8}))
	create.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var join: Button = menu._button(choices, "ENTRA CON CODICE", func(): _show_form(false))
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.add_theme_font_size_override("font_size", 22)
	controls = VBoxContainer.new()
	add_child(controls)
	controls.position = Vector2(640, 500)
	controls.size = Vector2(640, 400)
	controls.add_theme_constant_override("separation", 16)
	address = LineEdit.new()
	address.virtual_keyboard_enabled = true
	address.virtual_keyboard_show_on_focus = true
	address.text = net.endpoint
	address.placeholder_text = "Indirizzo server"
	menu._style_input(address, 24)
	# controls.add_child(address)
	code = LineEdit.new()
	code.virtual_keyboard_enabled = true
	code.virtual_keyboard_show_on_focus = true
	code.placeholder_text = "Codice stanza"
	code.max_length = 6
	code.custom_minimum_size = Vector2(500, 80)
	code.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu._style_input(code, 24)
	controls.add_child(code)
	match_options = preload("res://scenes/balatro/scripts/match_options.gd").new()
	controls.add_child(match_options)
	match_options.setup(menu, true)
	create_button = menu._button(controls, "Crea lobby", func():
		var command: Dictionary = match_options.values()
		command.merge({"op": "create", "name": menu.chosen_name(), "capacity": 8})
		net.connect_room(address.text, command)
	)
	join_button = menu._button(controls, "Entra", func(): net.connect_room(address.text, {"op": "join", "name": menu.chosen_name(), "code": code.text}))
	rejoin_button = menu._button(controls, "Rientra nella partita", func(): net.connect_room(address.text, {"op": "rejoin", "code": net.room_code, "token": net.token}))
	controls.hide()
	session_controls = Control.new()
	add_child(session_controls)
	session_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	code_button = menu._button(session_controls, "CODICE PARTITA", func():
		DisplayServer.clipboard_set(code_button.get_meta("room_code", ""))
		copied_code = str(code_button.get_meta("room_code", ""))
		info.text = "Codice copiato negli appunti"
	)
	code_button.position = Vector2(260, 130)
	code_button.custom_minimum_size = Vector2(420, 120)
	code_button.size = Vector2(420, 120)

	# Testo del codice separato dal Button, così può fare il tween da solo.
	code_button.text = ""
	code_button.icon = null

	code_label = Label.new()
	code_button.add_child(code_label)
	code_label.position = Vector2(+50, 4)
	code_label.size = code_button.size
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_label.add_theme_font_override("font", menu.KIDS_FONT)
	code_label.add_theme_font_size_override("font_size", 54)
	code_label.add_theme_color_override("font_color", menu.BUTTON_TEXT)
	code_label.pivot_offset = code_label.size / 2.0

	# Copy come figlia del code_button: segue hover/rotazione del bottone.
	copy_icon = TextureRect.new()
	code_button.add_child(copy_icon)
	copy_icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/copy.svg")
	copy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	copy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	copy_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	copy_icon.position = Vector2(25, 15)
	copy_icon.size = Vector2(96, 96)
	copy_icon.pivot_offset = copy_icon.size / 2.0
	copy_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Al click tweenano SOLO testo e copy, non il bottone.
	code_button.pressed.connect(func():
		var tween := create_tween()

		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(code_label, "scale", Vector2.ZERO, 0.12)
		# tween.parallel().tween_property(copy_icon, "scale", Vector2.ZERO, 0.12)

		tween.tween_callback(func():
			copy_icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/copy-success.svg")
		)

		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(code_label, "scale", Vector2.ONE, 0.22)
		# tween.parallel().tween_property(copy_icon, "scale", Vector2.ONE, 0.22)
	)
	
	lobby_options = preload("res://scenes/balatro/scripts/match_options.gd").new()
	session_controls.add_child(lobby_options)
	lobby_options.position = Vector2(260, 300)
	lobby_options.size = Vector2(430, 580)
	lobby_options.setup(menu, true)
	for slider in [lobby_options.lives, lobby_options.rounds, lobby_options.bot_count]:
		slider.value_changed.connect(func(_value): _send_options())
	lobby_options.fill_bots.toggled.connect(func(_value): _send_options())
	var participant_panel := PanelContainer.new()
	session_controls.add_child(participant_panel)
	participant_panel.position = Vector2(760, 130)
	participant_panel.size = Vector2(900, 760)
	var panel_style = menu._menu_button_style(menu.BUTTON_TEXT, menu.BUTTON_CYAN, 4)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 120
	participant_panel.add_theme_stylebox_override("panel", panel_style)
	players_box = VBoxContainer.new()
	players_box.add_theme_constant_override("separation", 8)
	participant_panel.add_child(players_box)
	start_button = menu._button(session_controls, "PLAY", func(): net.send({"op": "start"}))
	start_button.position = Vector2(1320, 755)
	start_button.size = Vector2(300, 80)
	start_button.custom_minimum_size.y = 80
	_set_icon(start_button, "play")
	session_controls.hide()
	info = Label.new()
	add_child(info)
	info.position = Vector2(500, 1020)
	info.size = Vector2(920, 40)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 24)
	var back_row := VBoxContainer.new()
	add_child(back_row)
	back_row.position = Vector2(50, 940)
	back_row.size.x = 260
	menu._button(back_row, "Indietro", _back)
	net.updated.connect(_update)
	net.problem.connect(func(message): info.text = message)

func open() -> void:
	show()
	entry.show()
	controls.hide()
	session_controls.hide()
	info.text = ""
	menu._show_menu_title(true)

func _show_form(creating: bool) -> void:
	code.visible = not creating
	match_options.visible = creating
	create_button.visible = creating
	join_button.visible = not creating
	rejoin_button.visible = not creating and not net.token.is_empty()
	info.text = ""
	preload("res://scenes/balatro/scripts/page_transition.gd").slide(self, entry, controls)

func _back() -> void:
	profile_picker.close()
	if controls.visible or session_controls.visible:
		var previous: Control = session_controls if session_controls.visible else controls
		if session_controls.visible:
			net.leave()
		info.text = ""
		menu._show_menu_title(true)
		preload("res://scenes/balatro/scripts/page_transition.gd").slide(self, previous, entry, true)
	else:
		menu.show_home()

func _update(state: Dictionary) -> void:
	if state.stage != "lobby":
		profile_picker.close()
		hide()
		return
	if profile_room != str(state.code):
		profile_room = str(state.code)
		net.send.call_deferred({"op": "profile", "avatar": menu.profile_avatar})
	if not session_controls.visible:
		menu.title.hide()
		menu.friends_subtitle.hide()
		preload("res://scenes/balatro/scripts/page_transition.gd").slide(self, entry if entry.visible else controls, session_controls)
	start_button.disabled = state.you != 0
	is_host = state.you == 0
	_sync_options(state)
	code_label.text = str(state.code)
	code_button.set_meta("room_code", state.code)
	copy_icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % ("copy-success" if copied_code == str(state.code) else "copy"))
	for child in players_box.get_children():
		players_box.remove_child(child)
		child.queue_free()
	for index in range(min(8, state.people.size())):
		var p: Dictionary = state.people[index]
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 64)
		row.clip_contents = true
		row.add_theme_stylebox_override("panel", menu._menu_button_style(menu.BUTTON_TEXT))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		row.add_child(line)
		var avatar := TextureRect.new()
		avatar.name = "Avatar"
		avatar.custom_minimum_size = Vector2(42, 42)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar.texture = net.avatar_for_slot(index)
		avatar.draw.connect(func():
			if avatar.texture == null:
				avatar.draw_circle(avatar.size / 2.0, 20, Color("e5e8d8"), true, -1, true)
		)
		line.add_child(avatar)
		row.set_meta("avatar_view", avatar)
		row.set_meta("slot", index)
		var name_button := Button.new()
		name_button.text = str(p.name) + ("  · OFFLINE" if not p.connected else "")
		name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_button.add_theme_font_override("font", menu.KIDS_FONT)
		name_button.add_theme_font_size_override("font_size", 24)
		name_button.add_theme_color_override("font_color", menu.BUTTON_PURPLE)
		name_button.flat = true
		line.add_child(name_button)
		var voice = get_node("/root/VoiceChat")
		var voice_id := str(p.get("voice_id", ""))
		var volume := HSlider.new()
		volume.min_value = 0
		volume.max_value = 100
		volume.step = 1
		volume.value = voice.player_volume(voice_id)
		volume.custom_minimum_size = Vector2(220, 50)
		volume.editable = index != int(state.you) and not bool(p.bot)
		var speaker := Button.new()
		line.add_child(speaker)
		speaker.custom_minimum_size = Vector2(56, 50)
		_set_icon(speaker, "volume-cross" if volume.value == 0 else "volume-high")
		speaker.disabled = not volume.editable
		speaker.pressed.connect(func(): volume.value = 100 if volume.value == 0 else 0)
		line.add_child(volume)
		volume.value_changed.connect(func(value):
			voice.set_player_volume(voice_id, value)
			_set_icon(speaker, "volume-cross" if value == 0 else "volume-high")
		)
		var remove := Button.new()
		RoundedSquareButton.ButtonAudio.attach(remove)
		remove.text = "×"
		remove.custom_minimum_size = Vector2(64, 50)
		remove.add_theme_font_override("font", menu.KIDS_FONT)
		remove.add_theme_font_size_override("font_size", 30)
		remove.add_theme_color_override("font_color", menu.BUTTON_PURPLE)
		remove.flat = true
		# Only the lobby creator sees removal controls, never on their own row.
		if state.you == 0 and index > 0:
			remove.pressed.connect(func(): net.send({"op": "kick", "slot": index}))
		else:
			remove.hide()
		line.add_child(remove)
		players_box.add_child(row)
	info.text = "In attesa dei giocatori…"

func _set_icon(button: Button, icon_name: String) -> void:
	button.icon = load("res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % icon_name)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 56)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _send_options() -> void:
	if syncing_options or not is_host or not session_controls.visible:
		return
	var command: Dictionary = lobby_options.values()
	command["op"] = "settings"
	net.send(command)

func _sync_options(state: Dictionary) -> void:
	syncing_options = true
	var options: Dictionary = state.get("options", {})
	lobby_options.lives.value = options.get("lives", 3)
	lobby_options.rounds.value = options.get("starting_cards", 5)
	lobby_options.bot_count.value = state.get("bot_count", 2)
	lobby_options.fill_bots.button_pressed = state.get("bots", false)
	lobby_options.bot_count.get_parent().visible = lobby_options.fill_bots.button_pressed
	for slider in [lobby_options.lives, lobby_options.rounds, lobby_options.bot_count]:
		slider.editable = is_host
	lobby_options.fill_bots.disabled = not is_host
	syncing_options = false

func _update_lobby_photos() -> void:
	if players_box == null:
		return
	for row in players_box.get_children():
		if row.has_meta("avatar_view"):
			row.get_meta("avatar_view").texture = net.avatar_for_slot(int(row.get_meta("slot")))
