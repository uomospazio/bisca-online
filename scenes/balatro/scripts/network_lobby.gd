extends Control

# Dimensioni logiche degli slot nella nuova lista illustrata.
const PLAYER_SLOT_HEIGHT := 80.0
const PLAYER_SLOT_WIDTH := 564.0

var entry_ui: Control
var lobby_ui: Control
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
var entry: Control
var create_button: Button
var join_button: Button
var rejoin_button: Button
var entry_buttons: Array[Button] = []
var form_intro: Tween
var profile_picker: Node
var profile_room := ""
var rendered_people: Array = []
var rendered_self := -1
var invite_box: Control
var invite_rows: VBoxContainer
var sending_invite := false
var directory_rows: VBoxContainer
var directory_panel: Control
var lobby_private: CheckButton
var directory_timer: Timer
var rendered_directory: Variant = null

func setup(owner_menu: Control) -> void:
	menu = owner_menu
	net = get_node("/root/NetworkSession")
	profile_picker = menu.profile_picker
	net.avatars_changed.connect(_update_lobby_photos)
	net.connection_lost.connect(profile_picker.close)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry_ui = preload("res://scenes/balatro/scripts/multiplayer_entry_ui.gd").new()
	add_child(entry_ui)
	entry_ui.setup(self)
	_render_directory([])
	net.lobby_directory_updated.connect(_render_directory)
	directory_timer = Timer.new()
	directory_timer.wait_time = 5.0
	directory_timer.autostart = true
	add_child(directory_timer)
	directory_timer.timeout.connect(func():
		if is_visible_in_tree() and entry.visible:
			net.browse_lobbies()
	)
	controls = VBoxContainer.new()
	add_child(controls)
	controls.position = Vector2(1100, 460) + menu.MULTIPLAYER_CONTENT_OFFSET
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
	code.custom_minimum_size = menu.PLAY_BUTTON_SIZE
	code.size = menu.PLAY_BUTTON_SIZE
	code.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	code.alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu._style_input(code, 36)
	for state in ["normal", "focus"]:
		var style := code.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.set_corner_radius_all(int(menu.PLAY_BUTTON_SIZE.y / 2.0))
		code.add_theme_stylebox_override(state, style)
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
	join_button.custom_minimum_size = menu.PLAY_BUTTON_SIZE
	join_button.size = menu.PLAY_BUTTON_SIZE
	join_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu._set_play_button_radius(join_button)
	rejoin_button = menu._button(controls, "Rientra nella partita", func(): net.connect_room(address.text, {"op": "rejoin", "code": net.room_code, "token": net.token}))
	for button in [create_button, join_button, rejoin_button]:
		preload("res://scenes/balatro/scripts/generic_ui_skin.gd").apply(button, true)
	controls.hide()
	session_controls = Control.new()
	add_child(session_controls)
	session_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	session_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	invite_box = preload("res://scenes/balatro/scripts/menu_dialog.gd").new()
	invite_box.title = "INVITA AMICI IN LOBBY"
	invite_box.ok_button_text = "CHIUDI"
	add_child(invite_box)
	var invite_scroll := preload("res://scenes/balatro/scripts/touch_scroll.gd").new()
	invite_scroll.custom_minimum_size = Vector2(620, 300)
	invite_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	invite_box.body.add_child(invite_scroll)
	invite_rows = VBoxContainer.new()
	invite_rows.size_flags_horizontal = SIZE_EXPAND_FILL
	invite_scroll.add_child(invite_rows)
	get_node("/root/FriendsManager").changed.connect(_refresh_invites)
	# The existing option controls remain the authoritative value/signal model.
	lobby_options = preload("res://scenes/balatro/scripts/match_options.gd").new()
	session_controls.add_child(lobby_options)
	lobby_options.setup(menu, true)
	lobby_options.hide()
	for slider in [lobby_options.lives, lobby_options.rounds, lobby_options.bot_count, lobby_options.turn_timer]:
		slider.value_changed.connect(func(_value): _send_options())
	lobby_options.fill_bots.toggled.connect(func(_value): _send_options())
	lobby_private = CheckButton.new()
	session_controls.add_child(lobby_private)
	lobby_private.hide()
	lobby_private.toggled.connect(func(value):
		if not syncing_options and is_host:
			net.send({"op": "visibility", "private": value})
	)
	lobby_ui = preload("res://scenes/balatro/scripts/in_lobby_ui.gd").new()
	session_controls.add_child(lobby_ui)
	lobby_ui.setup(self)
	session_controls.hide()
	info = Label.new()
	add_child(info)
	info.position = Vector2(500, 970)
	info.size = Vector2(920, 40)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color("f3effe"))
	entry_ui.attach_form()
	net.updated.connect(_update)
	net.problem.connect(func(message): info.text = message)
	get_node("/root/VoiceChat").changed.connect(_update_voice_buttons)

func _create_public_lobby() -> void:
	net.connect_room(net.endpoint, {"op": "create", "name": menu.chosen_name(), "directory_name": get_node("/root/AccountProfile").account_display_name(), "capacity": 8, "private": false})

func _join_directory(item: Dictionary) -> void:
	if item.get("rejoin", false):
		net.connect_room(net.endpoint, {"op": "rejoin", "code": net.room_code, "token": net.token})
	elif item.get("private", true):
		code.text = ""
		_show_form(false)
	else:
		net.connect_room(net.endpoint, {"op": "join_public", "id": item.id, "name": menu.chosen_name()})

func _render_directory(entries: Array) -> void:
	# Polling must not erase connection/error messages while a request is pending.
	if rendered_directory != null and rendered_directory == entries:
		return
	rendered_directory = entries.duplicate(true)
	entry_ui.render(entries)

func open() -> void:
	lobby_ui.stop_pop()
	match_options.reset_multiplayer()
	menu.show_network_entry_extras()
	show()
	controls.hide()
	session_controls.hide()
	info.text = ""
	entry_ui.attach_status()
	menu.title.hide()
	menu.friends_subtitle.hide()
	entry_ui.pop()
	net.browse_lobbies()

func _show_form(creating: bool) -> void:
	code.visible = not creating
	match_options.visible = creating
	create_button.visible = creating
	join_button.visible = not creating
	rejoin_button.visible = not creating and not net.token.is_empty()
	info.text = ""
	entry.hide()
	directory_panel.hide()
	controls.show()
	var items: Array[Control] = []
	for control in [code, match_options, create_button, join_button, rejoin_button]:
		if control.visible:
			items.append(control)
	_pop_form_controls(items)

func _pop_form_controls(items: Array[Control]) -> void:
	if form_intro and form_intro.is_valid():
		form_intro.kill()
	form_intro = create_tween().set_parallel(true)
	for index in items.size():
		var item := items[index]
		if item is RoundedSquareButton:
			item.hover_animate = false
			if item.hover_tween and item.hover_tween.is_valid():
				item.hover_tween.kill()
		item.release_focus()
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.focus_mode = Control.FOCUS_NONE
		item.modulate.a = 0.0
		item.scale = Vector2.ZERO
		var delay: float = menu.HOME_INTRO_DELAY + index * menu.HOME_INTRO_STAGGER
		form_intro.tween_callback(func():
			item.pivot_offset = item.size / 2.0
			item.modulate.a = 1.0
		).set_delay(delay)
		form_intro.tween_property(item, "scale", Vector2.ONE, menu.HOME_INTRO_DURATION).from(Vector2.ZERO).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		form_intro.tween_callback(func():
			item.mouse_filter = Control.MOUSE_FILTER_STOP
			item.focus_mode = Control.FOCUS_ALL
			if item is RoundedSquareButton:
				item.hover_animate = true
		).set_delay(delay + menu.HOME_INTRO_DURATION)

func _back() -> void:
	profile_picker.close()
	lobby_ui.stop_pop()
	if session_controls.visible:
		menu._send_profile_name()
		net.leave()
		profile_room = ""
		open()
	elif controls.visible:
		controls.hide()
		info.text = ""
		entry_ui.pop()
	else:
		menu.show_home()

func _update(state: Dictionary) -> void:
	if state.get("singleplayer", false):
		return
	directory_panel.hide()
	if state.stage != "lobby":
		invite_box.hide()
		profile_picker.close()
		hide()
		return
	if profile_room != str(state.code):
		profile_room = str(state.code)
		net.send.call_deferred({"op": "profile", "avatar": menu.profile_avatar})
	if not session_controls.visible:
		menu.hide_network_entry_extras()
		# Foto, campo nome e deck selector restano nella HOME:
		# non vengono più spostati nella schermata della lobby.
		menu.profile_panel.hide()
		menu.title.hide()
		if is_instance_valid(menu.home_character):
			menu.home_character.hide()
		menu.friends_subtitle.hide()
		entry.hide()
		controls.hide()
		entry_ui.hide()
		info.reparent(self, false)
		info.position = Vector2(500, 970)
		info.size = Vector2(920, 65)
		session_controls.show()
		entry_buttons[-1].hide()
		lobby_ui.pop()
	start_button.disabled = false
	var own_ready: bool = bool(state.people[int(state.you)].get("ready", false))
	lobby_ui.set_ready(own_ready)
	is_host = state.you == 0
	lobby_private.disabled = not is_host
	lobby_private.set_pressed_no_signal(bool(state.get("private", true)))
	_sync_options(state)
	lobby_ui.sync_options()
	code_label.text = str(state.code)
	code_button.set_meta("room_code", state.code)
	players_label.text = "%d/8" % min(8, state.people.size())
	copy_icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % ("copy-success" if copied_code == str(state.code) else "copy"))
	# Le opzioni stanza cambiano spesso senza modificare gli slot. In quel caso
	# conserviamo nodi, focus e tween invece di ricreare otto card.
	if rendered_self == int(state.you) and rendered_people == state.people:
		refresh_own_card()
		_update_voice_buttons()
		return
	rendered_people = state.people.duplicate(true)
	rendered_self = int(state.you)
	for child in players_box.get_children():
		players_box.remove_child(child)
		child.queue_free()
	for index in range(8):
		var row := PanelContainer.new()
		row.set_meta("cartoon_style_children_excluded", true)
		row.custom_minimum_size = Vector2(PLAYER_SLOT_WIDTH, PLAYER_SLOT_HEIGHT)
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.clip_contents = false
		lobby_ui.skin_slot(row, index >= state.people.size())
		if index >= state.people.size():
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
		name_button.add_theme_font_override("font", lobby_ui.scalable_font)
		name_button.add_theme_font_size_override("font_size", 24)
		name_button.add_theme_color_override("font_color", menu.BUTTON_TEXT)
		name_button.flat = true
		var name_padding := StyleBoxEmpty.new()
		name_padding.content_margin_top = 6
		name_button.add_theme_stylebox_override("normal", name_padding)
		line.add_child(name_button)
		var ready_dot := Label.new()
		ready_dot.text = "●"
		ready_dot.tooltip_text = "Pronto" if bool(p.get("ready", false)) else "Non pronto"
		ready_dot.add_theme_font_size_override("font_size", 24)
		ready_dot.add_theme_color_override("font_color", Color("48cf83") if bool(p.get("ready", false)) else Color("777583"))
		line.add_child(ready_dot)
		line.move_child(ready_dot, 0)
		if index == 0:
			name_button.tooltip_text = "Creatore della lobby"
		name_button.clip_text = true
		if index == int(state.you):
			var self_badge := TextureRect.new()
			self_badge.texture = load(lobby_ui.ART + "tu.png")
			self_badge.custom_minimum_size = Vector2(41, 41)
			self_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			self_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			self_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			self_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		remove.custom_minimum_size = Vector2(41, 41)
		remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		remove.tooltip_text = "Rimuovi giocatore"
		lobby_ui.skin_button(remove, "eliminaPlayer.png")
		# Only the lobby creator sees removal controls, never on their own row.
		if state.you == 0 and index > 0:
			remove.pressed.connect(func(): net.send({"op": "kick", "slot": index}))
		else:
			remove.hide()
		line.add_child(remove)
		players_box.add_child(row)
	info.text = ""
	refresh_own_card()
	_update_voice_buttons()

func _open_invites() -> void:
	invite_box.popup_centered(Vector2i(760,540))
	_refresh_invites()
	get_node("/root/FriendsManager").refresh()

func _refresh_invites() -> void:
	if not is_instance_valid(invite_box) or not invite_box.visible: return
	for child in invite_rows.get_children():
		invite_rows.remove_child(child)
		child.queue_free()
	var manager := get_node("/root/FriendsManager")
	var count := 0
	for friend in manager.entries:
		if friend.status != "accepted": continue
		count += 1
		var username := str(friend.get("username", "") if friend.get("username") != null else "").strip_edges()
		var public_id := str(friend.get("public_id", "") if friend.get("public_id") != null else "").strip_edges()
		var caption := username if not username.is_empty() else "#" + public_id
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 36)
		margin.add_theme_constant_override("margin_right", 36)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		invite_rows.add_child(margin)
		var button: Button = menu._button(margin, "INVITA " + caption, _send_invite.bind(str(friend.id)))
		button.clip_text = true
		button.custom_minimum_size = Vector2(0,68)
		_set_button_radius(button, 34)
		preload("res://scenes/balatro/scripts/generic_ui_skin.gd").apply(button, true)
		button.disabled = sending_invite
	if count == 0:
		var empty := Label.new()
		empty.text = "Nessun amico disponibile. Aggiungi amici dalla home."
		empty.add_theme_font_size_override("font_size",24)
		invite_rows.add_child(empty)

func _send_invite(target: String) -> void:
	if sending_invite or not session_controls.is_visible_in_tree() or net.room_code.is_empty(): return
	sending_invite = true
	_refresh_invites()
	var result: Dictionary = await get_node("/root/FriendsManager").call_api("bisca_invite_friend",{"target":target,"code":net.room_code})
	sending_invite = false
	invite_box.title = "INVITO INVIATO" if result.ok else "INVIO NON RIUSCITO - CONTROLLA SQL 009"
	_refresh_invites()

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

func _set_button_radius(button: Button, radius: int) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var base_style := button.get_theme_stylebox(state)
		if base_style is StyleBoxFlat:
			var style := (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
			style.set_corner_radius_all(radius)
			button.add_theme_stylebox_override(state, style)

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
	if str(icon.get_meta("current_icon", "")) == icon_name:
		return
	icon.set_meta("current_icon", icon_name)
	icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % icon_name)


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
	lobby_options.turn_timer.value = maxi(0, lobby_options.TURN_TIMES.find(int(options.get("turn_seconds", 30))))
	lobby_options.turn_timer.editable = is_host
	for slider in [lobby_options.lives, lobby_options.rounds, lobby_options.bot_count]:
		slider.editable = is_host
	lobby_options.update_bot_limit(maxi(0, 8 - state.people.size()), is_host)
	syncing_options = false

func _update_lobby_photos() -> void:
	if players_box == null:
		return
	for row in players_box.get_children():
		if row.has_meta("avatar_view"):
			row.get_meta("avatar_view").texture = net.avatar_for_slot(int(row.get_meta("slot")))
	refresh_own_card()
