extends Control
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
var manager: Node
var menu: Control
var query: LineEdit
var results: VBoxContainer
var contacts: VBoxContainer
var notice: Label
var working := false
var search_generation := 0
var identity := ""
var friends_box: Panel
var search_timer: Timer

func setup(host: Control) -> void:
	menu = host
	manager = get_node("/root/FriendsManager")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back: Button = menu._button(self, "INDIETRO", menu.show_home)
	back.position = Vector2(40, 1080 - 40 - 96)
	back.size = Vector2(260,96)
	_set_button_radius(back, 48)

	var title := preload("res://scenes/balatro/scripts/idle_subtitle.gd").new()
	add_child(title)
	title.text = "AMICI"
	title.position = Vector2(710,55)
	title.size = Vector2(500,90)
	title.add_theme_font_override("font",menu.KIDS_FONT)
	title.add_theme_font_size_override("font_size",58)
	title.set_animated(true)

	query = LineEdit.new()
	add_child(query)
	query.position = Vector2(180,180)
	query.size = Vector2(1050,70)
	query.custom_minimum_size.y = 70
	query.placeholder_text = "Cerca un amico per nome o #codice"
	query.max_length = 64
	query.add_theme_font_size_override("font_size",30)
	_set_line_edit_radius(query, 35)
	# Ricerca automatica mentre si scrive, con un piccolo debounce
	# per evitare una richiesta di rete a ogni singolo tasto.
	search_timer = Timer.new()
	search_timer.one_shot = true
	search_timer.wait_time = 0.35
	add_child(search_timer)
	search_timer.timeout.connect(search)

	query.text_changed.connect(func(_text):
		search_generation += 1
		search_timer.stop()
		clear(results)
		_show_search_results()
		notice.text = ""
		if query.text.strip_edges().length() >= 2:
			search_timer.start()
		else:
			clear(results)
			notice.text = ""
	)

	notice = label("",self)
	notice.position = Vector2(180,270)
	notice.size = Vector2(1560,90)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results = column(Vector2(180,380))
	contacts = column(Vector2(990,380))

	friends_box = Panel.new()
	add_child(friends_box)
	friends_box.position = Vector2(180, 210)
	friends_box.size = Vector2(1500, 720)
	friends_box.add_theme_stylebox_override("panel", Style.button_style(Style.PANEL, Style.HOVER, 4))
	query.reparent(friends_box)
	query.position = Vector2(24, 24)
	query.size = Vector2(1452, 70)
	_set_line_edit_radius(query, 35)
	var search_icon := TextureRect.new()
	query.add_child(search_icon)
	search_icon.texture = preload("res://scenes/balatro/trick_asset/ui_bisca/add_friends.svg")
	search_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	search_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	search_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	search_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	search_icon.position = Vector2(query.size.x - 62, 11)
	search_icon.size = Vector2(48, 48)
	query.text_submitted.connect(func(_text): search_timer.stop(); search())
	notice.reparent(friends_box)
	notice.position = Vector2(24, 106)
	notice.size = Vector2(1452, 56)
	for box in [contacts, results]:
		var scroll := box.get_parent() as ScrollContainer
		scroll.reparent(friends_box)
		scroll.position = Vector2(24, 174)
		scroll.size = Vector2(1452, 522)
	_show_search_results()

	manager.changed.connect(update_contacts)
	get_node("/root/AccountSession").changed.connect(_identity_changed)
	identity = str(get_node("/root/AccountSession").user_id)
	update_contacts()

func _show_search_results() -> void:
	var searching := query.text.strip_edges().length() >= 2
	results.get_parent().visible = searching
	contacts.get_parent().visible = not searching

func _set_button_radius(button: Button, radius: int) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var base_style := button.get_theme_stylebox(state)
		if base_style is StyleBoxFlat:
			var style := (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
			style.set_corner_radius_all(radius)
			button.add_theme_stylebox_override(state, style)

func _set_line_edit_radius(field: LineEdit, radius: int) -> void:
	for state in ["normal", "focus", "read_only"]:
		var base_style := field.get_theme_stylebox(state)
		if base_style is StyleBoxFlat:
			var style := (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
			style.set_corner_radius_all(radius)
			style.content_margin_right = 84
			field.add_theme_stylebox_override(state, style)

func label(text: String, parent: Node) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font",menu.KIDS_FONT)
	node.add_theme_font_size_override("font_size",26)
	node.add_theme_color_override("font_color",Style.TEXT)
	parent.add_child(node)
	return node

func column(at: Vector2) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	add_child(scroll)
	scroll.position = at
	scroll.size = Vector2(750,620)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",16)
	scroll.add_child(box)
	return box

func clear(box: VBoxContainer) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()

func _identity_changed() -> void:
	var next_identity := str(get_node("/root/AccountSession").user_id)
	if identity == next_identity: return
	identity = next_identity
	search_generation += 1
	if search_timer:
		search_timer.stop()
	clear(results)
	query.clear()
	_show_search_results()

func open() -> void:
	search_generation += 1
	search_timer.stop()
	query.clear()
	clear(results)
	notice.text = ""
	_show_search_results()
	manager.refresh()
	update_contacts()

func search() -> void:
	if not is_visible_in_tree(): return
	if working:
		search_timer.start()
		return

	var search_text := query.text.strip_edges()
	if search_text.length() < 2:
		return

	working = true
	var generation := search_generation
	var response: Dictionary = await manager.call_api("bisca_search_friends", {"query":search_text})
	working = false
	if generation != search_generation:
		if query.text.strip_edges().length() >= 2: search_timer.start()
		return
	clear(results)
	if not response.ok:
		notice.text = response.message
		return
	if not response.data is Array: return
	notice.text = "Nessun profilo trovato." if response.data.is_empty() else ""
	for row in response.data:
		label(manager.display_name(row),results)
		var button: Button = menu._button(results,"AGGIUNGI",act.bind(str(row.id),"request"))
		button.custom_minimum_size = Vector2(0,60)
		_set_button_radius(button, 30)

func act(target: String, action: String) -> void:
	if working: return
	working = true
	var generation := search_generation
	var response: Dictionary = await manager.call_api("bisca_friend_action",{"target":target,"action":action})
	working = false
	if generation != search_generation: return
	notice.text = "Operazione completata." if response.ok else response.message
	manager.refresh()

func _ask_remove_friend(target: String, display_name: String) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "RIMUOVI AMICO"
	dialog.dialog_text = "Vuoi rimuovere %s dagli amici?" % display_name
	dialog.ok_button_text = "RIMUOVI"
	dialog.cancel_button_text = "ANNULLA"
	add_child(dialog)
	dialog.confirmed.connect(func():
		dialog.queue_free()
		act(target, "remove"))
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(620, 220))

func answer_invite(sender: String, accept: bool) -> void:
	if working:
		return

	var net := get_node("/root/NetworkSession")

	var actually_in_lobby: bool = (
		not net.room_code.is_empty()
		and not net.latest.is_empty()
		and str(net.latest.get("code", "")) == net.room_code
	)

	if accept and actually_in_lobby:
		notice.text = "Esci prima dalla lobby attuale per accettare l'invito."
		return

	working = true
	var generation := search_generation
	var response: Dictionary = await manager.call_api(
		"bisca_answer_invite",
		{
			"from_user": sender,
			"accept": accept
		}
	)
	working = false

	if generation != search_generation:
		return

	if not response.ok:
		notice.text = "Invito scaduto o non disponibile."
	else:
		notice.text = "Invito rifiutato." if not accept else "Ingresso nella lobby..."
		if accept and response.data is String:
			menu._show_network()
			net.connect_room(
				net.endpoint,
				{
					"op": "join",
					"code": response.data,
					"name": menu.chosen_name()
				}
			)

	manager.refresh()

func update_contacts() -> void:
	clear(contacts)
	label("AMICI E RICHIESTE",contacts)
	for row in manager.entries:
		var tile := PanelContainer.new()
		tile.custom_minimum_size.y = 110
		var skin := Style.button_style(Style.NORMAL)
		skin.set_corner_radius_all(28)
		skin.set_content_margin_all(18)
		tile.add_theme_stylebox_override("panel",skin)
		contacts.add_child(tile)

		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation",20)
		tile.add_child(line)

		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(22,22)
		dot.size_flags_vertical = SIZE_SHRINK_CENTER
		var dot_skin := StyleBoxFlat.new()
		dot_skin.bg_color = Color("48cf83") if row.get("online",false) else Color("777583")
		dot_skin.set_corner_radius_all(11)
		dot.add_theme_stylebox_override("panel",dot_skin)
		dot.tooltip_text = "Online di recente" if row.get("online",false) else "Offline"
		line.add_child(dot)

		var identity_rows := VBoxContainer.new()
		identity_rows.size_flags_horizontal = SIZE_EXPAND_FILL
		line.add_child(identity_rows)
		label(manager.display_name(row),identity_rows)
		if row.status == "accepted":
			var remove := Button.new()
			remove.text = "×"
			remove.tooltip_text = "Rimuovi dagli amici"
			remove.custom_minimum_size = Vector2(58, 58)
			remove.size_flags_vertical = SIZE_SHRINK_CENTER
			remove.add_theme_font_override("font", menu.KIDS_FONT)
			remove.add_theme_font_size_override("font_size", 38)
			remove.add_theme_color_override("font_color", menu.BUTTON_TEXT)
			_set_button_radius(remove, 29)
			remove.pressed.connect(_ask_remove_friend.bind(str(row.id), manager.display_name(row)))
			line.add_child(remove)

		if row.has("invite_code"):
			label("Invito alla lobby " + str(row.invite_code),identity_rows)
			for accept in [true,false]:
				var invitation_button: Button = menu._button(line,"ACCETTA" if accept else "RIFIUTA",answer_invite.bind(str(row.id),accept))
				invitation_button.custom_minimum_size = Vector2(210,60)
				invitation_button.size_flags_vertical = SIZE_SHRINK_CENTER
				_set_button_radius(invitation_button, 30)

		if row.status != "accepted":
			label("Richiesta ricevuta" if row.incoming else "Richiesta inviata",identity_rows)
			var actions := ["accept","decline"] if row.incoming else ["cancel"]
			for action in actions:
				var button: Button = menu._button(line,{"accept":"ACCETTA","decline":"RIFIUTA","cancel":"ANNULLA"}[action],act.bind(str(row.id),action))
				button.custom_minimum_size = Vector2(210,60)
				button.size_flags_vertical = SIZE_SHRINK_CENTER
				_set_button_radius(button, 30)

	if not manager.error.is_empty(): notice.text = manager.error
