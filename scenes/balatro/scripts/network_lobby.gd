extends Control

# Altezza delle tessere giocatore; radius automaticamente pari a Y / 2.
const PLAYER_SLOT_HEIGHT := 78.0
# Larghezze indipendenti: lascia almeno 48 px fra box e tessere per i margini.
const PLAYER_SLOT_WIDTH := 600.0
const PLAYERS_PANEL_WIDTH := 660.0
# Spaziatura e dimensioni degli elementi centrati nel pulsante codice.
const LOBBY_CODE_ICON_SIZE := 96.0
const LOBBY_CODE_ICON_GAP := 16

var menu: Control
var net: Node
var address: LineEdit
var code: LineEdit
var match_options: PanelContainer
var info: Label
var start_button: Button
var ready_label: Label
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
var entry_buttons: Array[Button] = []
var form_intro: Tween
var profile_picker: Node
var profile_room := ""
var rendered_people: Array = []
var rendered_self := -1
var invite_box: AcceptDialog
var invite_rows: VBoxContainer
var sending_invite := false

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
	entry.position = Vector2(1100, 460)
	entry.size = Vector2(640, 200)
	entry.add_theme_constant_override("separation", 24)
	var choices := VBoxContainer.new()
	entry.add_child(choices)
	choices.add_theme_constant_override("separation", 24)
	var create: Button = menu._button(choices, "CREA LOBBY", func(): net.connect_room(net.endpoint, {"op": "create", "name": menu.chosen_name(), "capacity": 8}))
	var join: Button = menu._button(choices, "ENTRA CON CODICE", func(): _show_form(false))
	entry_buttons = [create, join]
	# Stesse dimensioni e forma a capsula dei pulsanti principali della HOME.
	for button in [create, join]:
		button.custom_minimum_size = menu.PLAY_BUTTON_SIZE
		button.size = menu.PLAY_BUTTON_SIZE
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		menu._set_play_button_radius(button)
	controls = VBoxContainer.new()
	add_child(controls)
	controls.position = Vector2(1100, 460)
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
	controls.hide()
	session_controls = Control.new()
	add_child(session_controls)
	session_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	session_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var invite_button: Button = menu._round_icon_button(session_controls,"add_friends.svg","Invita amici",_open_invites)
	invite_button.position = Vector2(1740,145)
	invite_button.size = Vector2.ONE * menu.ROUND_BUTTON_SIZE
	invite_box = AcceptDialog.new()
	invite_box.title = "INVITA AMICI IN LOBBY"
	invite_box.ok_button_text = "CHIUDI"
	add_child(invite_box)
	var invite_scroll := ScrollContainer.new()
	invite_scroll.custom_minimum_size = Vector2(700,440)
	invite_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	invite_box.add_child(invite_scroll)
	invite_rows = VBoxContainer.new()
	invite_rows.size_flags_horizontal = SIZE_EXPAND_FILL
	invite_scroll.add_child(invite_rows)
	get_node("/root/FriendsManager").changed.connect(_refresh_invites)
	code_button = menu._button(session_controls, "CODICE PARTITA", func():
		DisplayServer.clipboard_set(code_button.get_meta("room_code", ""))
		copied_code = str(code_button.get_meta("room_code", ""))
		info.text = "Codice copiato negli appunti"
	)
	code_button.position = Vector2(1050, 145)
	code_button.custom_minimum_size = Vector2(540, 200)
	code_button.size = Vector2(540, 200)
	_set_button_radius(code_button, 100)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var style := code_button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if style:
			style.border_color = menu.BUTTON_CYAN
			style.set_border_width_all(4)
			code_button.add_theme_stylebox_override(state, style)

	# Icona e codice formano un unico gruppo centrato automaticamente nel Button.
	# Il gruppo si ricentra anche quando cambia il testo (codice stanza).
	code_button.text = ""
	code_button.icon = null
	var code_center := CenterContainer.new()
	code_center.name = "CodeCenter"
	code_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_button.add_child(code_center)
	code_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var code_row := HBoxContainer.new()
	code_row.name = "CodeRow"
	code_row.alignment = BoxContainer.ALIGNMENT_CENTER
	code_row.add_theme_constant_override("separation", LOBBY_CODE_ICON_GAP)
	code_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_center.add_child(code_row)

	copy_icon = TextureRect.new()
	code_row.add_child(copy_icon)
	copy_icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/copy.svg")
	copy_icon.custom_minimum_size = Vector2.ONE * LOBBY_CODE_ICON_SIZE
	copy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	copy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	copy_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	copy_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	code_label = Label.new()
	code_row.add_child(code_label)
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	code_label.add_theme_font_override("font", menu.KIDS_FONT)
	code_label.add_theme_font_size_override("font_size", 84)
	code_label.add_theme_color_override("font_color", menu.BUTTON_TEXT)
	# Il pivot segue le dimensioni calcolate dal contenitore, per il tween.
	code_label.resized.connect(func(): code_label.pivot_offset = code_label.size / 2.0)
	copy_icon.resized.connect(func(): copy_icon.pivot_offset = copy_icon.size / 2.0)

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
	lobby_options.position = Vector2(1050, 370)
	lobby_options.size = Vector2(540, 561)
	lobby_options.setup(menu, true)
	for slider in [lobby_options.lives, lobby_options.rounds, lobby_options.bot_count]:
		slider.value_changed.connect(func(_value): _send_options())
	lobby_options.fill_bots.toggled.connect(func(_value): _send_options())
	var participant_panel := PanelContainer.new()
	session_controls.add_child(participant_panel)
	participant_panel.position = Vector2(350, 140)
	participant_panel.size = Vector2(PLAYERS_PANEL_WIDTH, 790)
	var panel_style = menu._menu_button_style(menu.LexispellStyle.PANEL, menu.BUTTON_CYAN, 4)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 32
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
	players_label.add_theme_color_override("font_color", menu.BUTTON_TEXT)
	participant_content.add_child(players_label)

	players_box = VBoxContainer.new()
	players_box.add_theme_constant_override("separation", 8)
	participant_content.add_child(players_box)
	start_button = menu._button(session_controls, "PRONTO", func():
		var people: Array = net.latest.get("people", [])
		var own := int(net.latest.get("you", -1))
		if own >= 0 and own < people.size():
			net.send({"op": "ready", "ready": not bool(people[own].get("ready", false))})
	)
	start_button.position = Vector2(1300, 800)
	start_button.size = Vector2(260, 80)
	start_button.custom_minimum_size.y = 80
	# PLAY a capsula: radius = meta della sua altezza (Y/2).
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var base_style := start_button.get_theme_stylebox(state)
		if base_style is StyleBoxFlat:
			var style := (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
			style.set_corner_radius_all(int(start_button.size.y / 2.0))
			start_button.add_theme_stylebox_override(state, style)
	_set_icon(start_button, "play")
	session_controls.hide()
	info = Label.new()
	add_child(info)
	info.position = Vector2(500, 1020)
	info.size = Vector2(920, 40)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color("f3effe"))
	var back_button: Button = menu._button(self, "Indietro", _back)
	menu.match_singleplayer_back(back_button)
	entry_buttons.append(back_button)
	net.updated.connect(_update)
	net.problem.connect(func(message): info.text = message)
	get_node("/root/VoiceChat").changed.connect(_update_voice_buttons)

func open() -> void:
	menu.show_network_entry_extras()
	show()
	entry.show()
	for button in entry_buttons:
		# Il layout iniziale dei Container puo' ripristinare la scala.
		# Restano trasparenti fino all'inizio del proprio pop.
		button.modulate.a = 0.0
		button.scale = Vector2.ZERO
	controls.hide()
	session_controls.hide()
	info.text = ""
	menu._show_menu_title(true)
	_animate_entry_buttons.call_deferred()

func _animate_entry_buttons() -> void:
	if is_visible_in_tree() and entry.visible:
		menu.animate_buttons_like_home(entry_buttons)

func _show_form(creating: bool) -> void:
	code.visible = not creating
	match_options.visible = creating
	create_button.visible = creating
	join_button.visible = not creating
	rejoin_button.visible = not creating and not net.token.is_empty()
	info.text = ""
	entry.hide()
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
	if controls.visible and not session_controls.visible:
		controls.hide()
		entry.show()
		info.text = ""
		# Indietro, titolo e personaggio restano gia' visibili.
		var choices: Array[Control] = [entry_buttons[0], entry_buttons[1]]
		_pop_form_controls(choices)
		return
	if controls.visible or session_controls.visible:
		var previous: Control = session_controls if session_controls.visible else controls
		if session_controls.visible:
			menu._send_profile_name()
			net.leave()
			profile_room = ""
		menu.profile_panel.hide()
		info.text = ""
		menu._show_menu_title(true)
		menu.show_network_entry_extras()
		menu._animate_mode_heading("WITH YOUR FRIENDS")
		preload("res://scenes/balatro/scripts/page_transition.gd").slide(self, previous, entry, true)
	else:
		menu.show_home()

func _update(state: Dictionary) -> void:
	if state.get("singleplayer", false):
		return
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
		preload("res://scenes/balatro/scripts/page_transition.gd").slide(self, entry if entry.visible else controls, session_controls)
	start_button.disabled = false
	var own_ready: bool = bool(state.people[int(state.you)].get("ready", false))
	ready_label.text = "ANNULLA" if own_ready else "PRONTO"
	is_host = state.you == 0
	_sync_options(state)
	code_label.text = str(state.code)
	code_button.set_meta("room_code", state.code)
	players_label.text = "PLAYERS %d/8" % min(8, state.people.size())
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
		# Decorate the entire player tile, leaving name/microphone/kick intact.
		row.draw.connect(func():
			var left := PLAYER_SLOT_HEIGHT * 0.5
			var right := row.size.x - left
			row.draw_line(Vector2(left, 6), Vector2(right, 6), Color(1, 1, 1, 0.8), 3, true)
			row.draw_line(Vector2(left, row.size.y - 9), Vector2(right, row.size.y - 9), Color(0, 0, 0, 0.26), 7, true)
		)
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
		var ready_dot := Label.new()
		ready_dot.text = "●"
		ready_dot.tooltip_text = "Pronto" if bool(p.get("ready", false)) else "Non pronto"
		ready_dot.add_theme_font_size_override("font_size", 24)
		ready_dot.add_theme_color_override("font_color", Color("48cf83") if bool(p.get("ready", false)) else Color("777583"))
		line.add_child(ready_dot)
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
		var button: Button = menu._button(invite_rows,"INVITA " + manager.display_name(friend),_send_invite.bind(str(friend.id)))
		button.custom_minimum_size = Vector2(0,68)
		_set_button_radius(button, 34)
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

func _style_player_slot(style: StyleBoxFlat) -> void:
	style.set_corner_radius_all(int(PLAYER_SLOT_HEIGHT / 2.0))
	style.corner_detail = 16
	style.set_border_width_all(4)
	style.border_width_bottom = 8
	style.border_color = menu.LexispellStyle.SHADOW
	style.shadow_color = Color(0.047059, 0.035294, 0.094118, 0.28)
	style.shadow_size = 1
	style.shadow_offset = Vector2(0, 5)
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
	if str(icon.get_meta("current_icon", "")) == icon_name:
		return
	icon.set_meta("current_icon", icon_name)
	icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % icon_name)


func _set_icon(button: Button, icon_name: String) -> void:
	# Centra icona e testo PLAY come un singolo gruppo.
	button.text = ""
	button.icon = null

	var center := CenterContainer.new()
	center.name = "PlayCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var content := HBoxContainer.new()
	content.name = "PlayContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(content)

	var icon := TextureRect.new()
	icon.texture = load("res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % icon_name)
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	var label := Label.new()
	label.text = "PRONTO"
	ready_label = label
	label.add_theme_font_override("font", menu.KIDS_FONT)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", menu.BUTTON_TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)


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
