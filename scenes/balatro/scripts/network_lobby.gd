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
var players_label: Label
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
	net.avatars_changed.connect(_update_lobby_photos)
	net.connection_lost.connect(profile_picker.close)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry = VBoxContainer.new()
	add_child(entry)
	entry.position = Vector2(180, 460)
	entry.size = Vector2(640, 200)
	entry.add_theme_constant_override("separation", 24)
	var choices := VBoxContainer.new()
	entry.add_child(choices)
	choices.add_theme_constant_override("separation", 24)
	var create: Button = menu._button(choices, "CREA LOBBY", func(): net.connect_room(net.endpoint, {"op": "create", "name": menu.chosen_name(), "capacity": 8}))
	create.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var join: Button = menu._button(choices, "ENTRA CON CODICE", func(): _show_form(false))
	join.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join.add_theme_font_size_override("font_size", 22)
	controls = VBoxContainer.new()
	add_child(controls)
	controls.position = Vector2(180, 460)
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
	session_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_button = menu._button(session_controls, "CODICE PARTITA", func():
		DisplayServer.clipboard_set(code_button.get_meta("room_code", ""))
		copied_code = str(code_button.get_meta("room_code", ""))
		info.text = "Codice copiato negli appunti"
	)
	code_button.position = Vector2(90, 310)
	code_button.custom_minimum_size = Vector2(420, 80)
	code_button.size = Vector2(420, 80)

	# Testo del codice separato dal Button, così può fare il tween da solo.
	code_button.text = ""
	code_button.icon = null

	code_label = Label.new()
	code_button.add_child(code_label)
	code_label.position = Vector2(85, 0)
	code_label.size = Vector2(320, 80)
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_label.add_theme_font_override("font", menu.KIDS_FONT)
	code_label.add_theme_font_size_override("font_size", 38)
	code_label.add_theme_color_override("font_color", menu.BUTTON_TEXT)
	code_label.pivot_offset = code_label.size / 2.0

	# Copy come figlia del code_button: segue hover/rotazione del bottone.
	copy_icon = TextureRect.new()
	code_button.add_child(copy_icon)
	copy_icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/copy.svg")
	copy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	copy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	copy_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	copy_icon.position = Vector2(20, 12)
	copy_icon.size = Vector2(56, 56)
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
	lobby_options.position = Vector2(90, 405)
	lobby_options.size = Vector2(430, 490)
	lobby_options.setup(menu, true)
	for slider in [lobby_options.lives, lobby_options.rounds, lobby_options.bot_count]:
		slider.value_changed.connect(func(_value): _send_options())
	lobby_options.fill_bots.toggled.connect(func(_value): _send_options())
	var participant_panel := PanelContainer.new()
	session_controls.add_child(participant_panel)
	participant_panel.position = Vector2(990, 140)
	participant_panel.size = Vector2(840, 790)
	var panel_style = menu._menu_button_style(menu.BUTTON_TEXT, menu.BUTTON_CYAN, 4)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	participant_panel.add_theme_stylebox_override("panel", panel_style)
	var participant_content := VBoxContainer.new()
	participant_content.add_theme_constant_override("separation", 14)
	participant_panel.add_child(participant_content)

	players_label = Label.new()
	players_label.text = "PLAYERS 0/8"
	players_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	players_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	players_label.custom_minimum_size.y = 42
	players_label.add_theme_font_override("font", menu.KIDS_FONT)
	players_label.add_theme_font_size_override("font_size", 28)
	players_label.add_theme_color_override("font_color", menu.BUTTON_PURPLE)
	participant_content.add_child(players_label)

	players_box = VBoxContainer.new()
	players_box.add_theme_constant_override("separation", 8)
	participant_content.add_child(players_box)
	start_button = menu._button(session_controls, "PLAY", func(): net.send({"op": "start"}))
	start_button.position = Vector2(1600, 940)
	start_button.size = Vector2(260, 80)
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
	back_row.position = Vector2(60, 960)
	back_row.size.x = 260
	menu._button(back_row, "Indietro", _back)
	net.updated.connect(_update)
	net.problem.connect(func(message): info.text = message)
	get_node("/root/VoiceChat").changed.connect(_update_voice_buttons)

func open() -> void:
	menu.profile_panel.hide()
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
			menu._send_profile_name()
			net.leave()
			profile_room = ""
		menu.profile_panel.hide()
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
		menu.profile_panel.reparent(session_controls, false)
		session_controls.move_child(menu.profile_panel, 0)
		menu.profile_panel.position = Vector2(60, 140)
		menu.profile_panel.show()
		menu.title.hide()
		if is_instance_valid(menu.home_character):
			menu.home_character.hide()
		menu.friends_subtitle.hide()
		preload("res://scenes/balatro/scripts/page_transition.gd").slide(self, entry if entry.visible else controls, session_controls)
	start_button.disabled = state.you != 0
	is_host = state.you == 0
	_sync_options(state)
	code_label.text = str(state.code)
	code_button.set_meta("room_code", state.code)
	players_label.text = "PLAYERS %d/8" % min(8, state.people.size())
	copy_icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % ("copy-success" if copied_code == str(state.code) else "copy"))
	for child in players_box.get_children():
		players_box.remove_child(child)
		child.queue_free()
	for index in range(8):
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(780, 78)
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.clip_contents = true
		var row_style = menu._menu_button_style(menu.BUTTON_PURPLE)
		row_style.shadow_size = 0
		row_style.shadow_offset = Vector2.ZERO
		_style_player_slot(row_style)
		row.add_theme_stylebox_override("panel", row_style)

		if index >= state.people.size():
			var empty_style = menu._menu_button_style(menu.LexispellStyle.DISABLED)
			empty_style.shadow_size = 0
			empty_style.shadow_offset = Vector2.ZERO
			_style_player_slot(empty_style)
			row.add_theme_stylebox_override("panel", empty_style)
			var empty := Label.new()
			empty.text = "EMPTY"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty.add_theme_font_override("font", menu.KIDS_FONT)
			empty.add_theme_font_size_override("font_size", 24)
			empty.add_theme_color_override("font_color", menu.LexispellStyle.DISABLED_TEXT)
			row.add_child(empty)
			players_box.add_child(row)
			continue
		var p: Dictionary = state.people[index]
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
				avatar.draw_circle(avatar.size / 2.0, 20, Color("efecfa"), true, -1, true)
		)
		line.add_child(avatar)
		row.set_meta("avatar_view", avatar)
		row.set_meta("slot", index)
		row.set_meta("own_card", index == int(state.you))
		var name_button := Button.new()
		row.set_meta("name_view", name_button)
		name_button.text = str(p.name) + ("  · OFFLINE" if not p.connected else "")
		name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_button.add_theme_font_override("font", menu.KIDS_FONT)
		name_button.add_theme_font_size_override("font_size", 24)
		name_button.add_theme_color_override("font_color", menu.BUTTON_TEXT)
		name_button.flat = true
		line.add_child(name_button)
		if index == 0:
			var crown := TextureRect.new()
			crown.texture = preload("res://scenes/balatro/trick_asset/ui_bisca/crown.svg")
			crown.custom_minimum_size = Vector2(30, 30)
			crown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			crown.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			crown.tooltip_text = "Creatore della lobby"
			line.add_child(crown)
		if index == int(state.you):
			var self_badge := PanelContainer.new()
			self_badge.custom_minimum_size = Vector2(44, 44)
			self_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			self_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var badge_style := StyleBoxFlat.new()
			badge_style.bg_color = menu.LexispellStyle.HOVER
			badge_style.set_corner_radius_all(99)
			badge_style.corner_detail = 16
			badge_style.set_border_width_all(2)
			badge_style.border_color = menu.LexispellStyle.SHADOW
			self_badge.add_theme_stylebox_override("panel", badge_style)
			var self_label := Label.new()
			self_label.text = "TU"
			self_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			self_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			self_label.add_theme_font_override("font", menu.KIDS_FONT)
			self_label.add_theme_font_size_override("font_size", 16)
			self_label.add_theme_color_override("font_color", menu.BUTTON_TEXT)
			self_badge.add_child(self_label)
			line.add_child(self_badge)
		var voice = get_node("/root/VoiceChat")
		var voice_id := str(p.get("voice_id", ""))
		var speaker := Button.new()
		line.add_child(speaker)
		if index == int(state.you):
			# Keep the TU badge last, after the microphone control.
			line.move_child(speaker, line.get_child_count() - 2)
		speaker.custom_minimum_size = Vector2(56, 50)
		speaker.flat = true
		speaker.icon = null
		RoundedSquareButton.ButtonAudio.attach(speaker)

		var speaker_icon := TextureRect.new()
		speaker.add_child(speaker_icon)
		speaker_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		speaker_icon.offset_left = 6
		speaker_icon.offset_top = 3
		speaker_icon.offset_right = -6
		speaker_icon.offset_bottom = -3
		speaker_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		speaker_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		speaker_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		speaker_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

		row.set_meta("voice_button", speaker)
		row.set_meta("voice_icon", speaker_icon)
		row.set_meta("voice_self", index == int(state.you))
		row.set_meta("voice_id", voice_id)
		row.set_meta("voice_bot", bool(p.bot))
		row.set_meta("voice_active", bool(p.get("voice_active", false)))
		if index == int(state.you):
			speaker.pressed.connect(voice.toggle_audio)
		else:
			speaker.disabled = true
			speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			speaker.focus_mode = Control.FOCUS_NONE
		var remove := Button.new()
		RoundedSquareButton.ButtonAudio.attach(remove)
		remove.text = "×"
		remove.custom_minimum_size = Vector2(44, 44)
		remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		remove.add_theme_font_override("font", menu.KIDS_FONT)
		remove.add_theme_font_size_override("font_size", 30)
		for state_color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			remove.add_theme_color_override(state_color, menu.BUTTON_TEXT)
		for skin_state in ["normal", "hover", "pressed", "focus"]:
			var remove_style := StyleBoxFlat.new()
			remove_style.bg_color = menu.LexispellStyle.NORMAL if skin_state == "pressed" else menu.LexispellStyle.HOVER
			remove_style.set_corner_radius_all(99)
			remove_style.corner_detail = 16
			remove_style.set_border_width_all(2)
			remove_style.border_color = menu.BUTTON_TEXT if skin_state in ["hover", "focus"] else menu.LexispellStyle.SHADOW
			remove.add_theme_stylebox_override(skin_state, remove_style)
		# Only the lobby creator sees removal controls, never on their own row.
		if state.you == 0 and index > 0:
			remove.pressed.connect(func(): net.send({"op": "kick", "slot": index}))
		else:
			remove.hide()
		line.add_child(remove)
		players_box.add_child(row)
	info.text = "In attesa dei giocatori…"
	refresh_own_card()
	_update_voice_buttons()

func refresh_own_card() -> void:
	if not is_instance_valid(players_box):
		return
	for row in players_box.get_children():
		if not row.get_meta("own_card", false):
			continue
		row.get_meta("name_view").text = menu.chosen_name()
		var avatar: TextureRect = row.get_meta("avatar_view")
		avatar.texture = menu.profile_texture
		avatar.queue_redraw()

func _style_player_slot(style: StyleBoxFlat) -> void:
	style.set_corner_radius_all(12)
	style.corner_detail = 16
	style.set_border_width_all(2)
	style.border_color = menu.LexispellStyle.SHADOW
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10

func _update_voice_buttons() -> void:
	if players_box == null:
		return
	var voice = get_node("/root/VoiceChat")
	for row in players_box.get_children():
		if not row.has_meta("voice_button"):
			continue
		var speaker: Button = row.get_meta("voice_button")
		var speaker_icon: TextureRect = row.get_meta("voice_icon")
		var active: bool
		if row.get_meta("voice_self"):
			active = voice.enabled and not voice.muted and not voice.pending
			speaker.tooltip_text = "Annulla connessione" if voice.pending else ("Disattiva chat vocale" if active else "Attiva chat vocale")
			_set_voice_icon_tween(speaker_icon, "mic-on" if active else "mic-off")
		else:
			active = bool(row.get_meta("voice_active", false))
			speaker.tooltip_text = "Microfono attivo" if active else "Microfono disattivato"
			_set_voice_icon(speaker_icon, "volume-high" if active else "volume-cross")
	if session_controls.visible and (voice.enabled or voice.pending or voice.status.begins_with("Errore") or voice.status.begins_with("Microfono")):
		info.text = voice.status

func _set_voice_icon_tween(icon: TextureRect, icon_name: String) -> void:
	var current_icon := str(icon.get_meta("current_icon", ""))

	# Prima assegnazione: niente animazione.
	if current_icon.is_empty():
		icon.texture = load(
			"res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % icon_name
		)
		icon.set_meta("current_icon", icon_name)
		return

	# Se l'icona non è cambiata, non fare nulla.
	if current_icon == icon_name:
		return

	# Interrompe un eventuale tween precedente.
	if icon.has_meta("voice_tween"):
		var old_tween: Tween = icon.get_meta("voice_tween")
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	icon.pivot_offset = icon.size / 2.0

	var tween := create_tween()
	icon.set_meta("voice_tween", tween)

	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(icon, "scale", Vector2(0.25, 0.25), 0.10)

	tween.tween_callback(func():
		icon.texture = load(
			"res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % icon_name
		)
		icon.set_meta("current_icon", icon_name)
	)

	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.18)


func _set_voice_icon(icon: TextureRect, icon_name: String) -> void:
	icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % icon_name)


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
	refresh_own_card()
