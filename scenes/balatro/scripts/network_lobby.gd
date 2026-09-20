extends Control

var menu: Control
var net: Node
var address: LineEdit
var code: LineEdit
var match_options: PanelContainer
var info: Label
var start_button: Button
var controls: VBoxContainer
var session_controls: VBoxContainer
var players_box: VBoxContainer
var code_button: Button
var entry: VBoxContainer
var create_button: Button
var join_button: Button
var rejoin_button: Button

func setup(owner_menu: Control) -> void:
	menu = owner_menu
	net = get_node("/root/NetworkSession")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	entry = VBoxContainer.new()
	add_child(entry)
	entry.position = Vector2(640, 530)
	entry.size = Vector2(640, 200)
	entry.add_theme_constant_override("separation", 24)
	menu.name_input.reparent(entry)
	menu.name_input.custom_minimum_size.y = 72
	menu.name_input.show()
	var choices := HBoxContainer.new()
	entry.add_child(choices)
	choices.add_theme_constant_override("separation", 24)
	var create: Button = menu._button(choices, "CREA LOBBY", func(): _show_form(true))
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
	session_controls = VBoxContainer.new()
	add_child(session_controls)
	session_controls.position = Vector2(600, 240)
	session_controls.size = Vector2(720, 630)
	session_controls.add_theme_constant_override("separation", 18)
	code_button = menu._button(session_controls, "CODICE PARTITA", func():
		DisplayServer.clipboard_set(code_button.get_meta("room_code", ""))
		info.text = "Codice copiato negli appunti"
	)
	code_button.custom_minimum_size = Vector2(720, 64)
	players_box = VBoxContainer.new()
	players_box.add_theme_constant_override("separation", 8)
	players_box.custom_minimum_size = Vector2(720, 456)
	session_controls.add_child(players_box)
	start_button = menu._button(session_controls, "Avvia partita", func(): net.send({"op": "start"}))
	start_button.custom_minimum_size = Vector2(720, 72)
	session_controls.hide()
	info = Label.new()
	add_child(info)
	info.position = Vector2(500, 1020)
	info.size = Vector2(920, 40)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 24)
	var back_row := VBoxContainer.new()
	add_child(back_row)
	back_row.position = Vector2(45, 950)
	back_row.size.x = 300
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
		hide()
		return
	if not session_controls.visible:
		menu.title.hide()
		menu.friends_subtitle.hide()
		preload("res://scenes/balatro/scripts/page_transition.gd").slide(self, controls, session_controls)
	start_button.disabled = state.you != 0
	code_button.text = "CODICE LOBBY: " + str(state.code)
	code_button.set_meta("room_code", state.code)
	for child in players_box.get_children():
		child.queue_free()
	for index in range(min(8, state.people.size())):
		var p: Dictionary = state.people[index]
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(720, 50)
		row.clip_contents = true
		row.add_theme_stylebox_override("panel", menu._menu_button_style(menu.BUTTON_PURPLE))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		row.add_child(line)
		var name_button := Button.new()
		name_button.text = str(p.name) + ("  · OFFLINE" if not p.connected else "")
		name_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_button.add_theme_font_override("font", menu.KIDS_FONT)
		name_button.add_theme_font_size_override("font_size", 24)
		name_button.add_theme_color_override("font_color", menu.BUTTON_TEXT)
		name_button.flat = true
		line.add_child(name_button)
		var remove := Button.new()
		RoundedSquareButton.ButtonAudio.attach(remove)
		remove.text = "×"
		remove.custom_minimum_size = Vector2(64, 50)
		remove.add_theme_font_override("font", menu.KIDS_FONT)
		remove.add_theme_font_size_override("font_size", 30)
		remove.add_theme_color_override("font_color", menu.BUTTON_TEXT)
		remove.flat = true
		# Only the lobby creator sees removal controls, never on their own row.
		if state.you == 0 and index > 0:
			remove.pressed.connect(func(): net.send({"op": "kick", "slot": index}))
		else:
			remove.hide()
		line.add_child(remove)
		players_box.add_child(row)
	info.text = "In attesa dei giocatori…"
