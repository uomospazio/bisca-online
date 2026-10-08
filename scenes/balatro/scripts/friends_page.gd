extends Control
const Look = preload("res://scenes/balatro/scripts/friends_look.gd")
const UI := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/AmiciUI/"
const BOX_SIZE := Vector2(1400, 790)
# Scala uniforme dal centro: 1.0 = attuale, 1.1 = +10%.
@export_range(0.1, 3.0, 0.01) var friends_scale := 1.25:
	set(value):
		friends_scale = maxf(value, 0.1)
		_apply_friends_transform()
# Spostamento dal centro: X positivo = destra, Y positivo = basso.
@export var friends_offset := Vector2.ZERO:
	set(value):
		friends_offset = value
		_apply_friends_transform()
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

func _apply_friends_transform() -> void:
	if not is_instance_valid(friends_box):
		return
	friends_box.pivot_offset = BOX_SIZE * 0.5
	friends_box.scale = Vector2.ONE * friends_scale
	friends_box.position = (Vector2(1920, 1080) - BOX_SIZE) * 0.5 + friends_offset

func setup(host: Control) -> void:
	menu = host
	manager = get_node("/root/FriendsManager")
	set_meta("cartoon_style_children_excluded", true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back := action_button(self, "←", menu.show_home, "Indietro")
	back.position = Vector2(10, 40)
	back.size = Vector2(140, 140)
	preload("res://scenes/balatro/scripts/safe_edges.gd").attach(back)
	friends_box = Panel.new()
	add_child(friends_box)
	friends_box.size = BOX_SIZE
	_apply_friends_transform()
	friends_box.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var background := TextureRect.new()
	friends_box.add_child(background)
	background.texture = load(UI + "boxAmici.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Title, magnifier and add-friend symbol are already baked into the panel.
	query = LineEdit.new()
	friends_box.add_child(query)
	query.position = Vector2(166, 157)
	query.size = Vector2(1070, 88)
	query.placeholder_text = "Cerca un amico per nome o #codice"
	query.max_length = 64
	query.add_theme_font_override("font", menu.KIDS_FONT)
	query.add_theme_font_size_override("font_size", 28)
	query.add_theme_color_override("font_color", Color("faf6ff"))
	query.add_theme_color_override("font_placeholder_color", Color("b6a0ed"))
	for state in ["normal", "focus", "read_only"]:
		query.add_theme_stylebox_override(state, Look.padding(4))
	notice = label("", friends_box)
	notice.position = Vector2(48, 802)
	notice.size = Vector2(1304, 66)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_size_override("font_size", 22)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results = column(Vector2.ZERO)
	contacts = column(Vector2.ZERO)
	for box in [contacts, results]:
		var scroll := box.get_parent() as ScrollContainer
		scroll.reparent(friends_box)
		scroll.position = Vector2(48, 270)
		scroll.size = Vector2(1304, 487)
		var bar := scroll.get_v_scroll_bar()
		var track := StyleBoxFlat.new()
		track.bg_color = Color("30234e")
		track.set_corner_radius_all(7)
		track.content_margin_left = 5
		track.content_margin_right = 5
		bar.add_theme_stylebox_override("scroll", track)
		for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
			var grab := track.duplicate()
			grab.bg_color = Color("b38af8")
			bar.add_theme_stylebox_override(state, grab)
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
	)
	query.text_submitted.connect(func(_text): search_timer.stop(); search())
	_show_search_results()
	manager.changed.connect(update_contacts)
	get_node("/root/AccountSession").changed.connect(_identity_changed)
	identity = str(get_node("/root/AccountSession").user_id)
	update_contacts()

func action_button(parent: Node, text: String, callback: Callable, hint := "", positive := false) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(72, 72) if text != "ANNULLA" else Vector2(242, 72)
	button.size_flags_vertical = SIZE_SHRINK_CENTER
	var asset := "confermaAmici.png" if positive else "declinaAmici.png"
	if text == "←": asset = "tastoIndietro.png"
	elif text == "ANNULLA": asset = "annullaAmici.png"
	if text == "+":
		button.text = "+"
		button.add_theme_font_override("font", ThemeDB.fallback_font)
		button.add_theme_font_size_override("font_size", 48)
		Look.decorate(button, 36.0, Color("38245a"))
	else:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var skin := StyleBoxTexture.new()
			skin.texture = load(UI + asset)
			skin.modulate_color = Color(1.15, 1.15, 1.15) if state == "hover" else (Color(0.8, 0.8, 0.8) if state == "pressed" else Color.WHITE)
			button.add_theme_stylebox_override(state, skin)
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = Color("baa0ff")
		focus.set_border_width_all(2)
		focus.set_corner_radius_all(36)
		button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(callback)
	return button

func contact_tile(row: Dictionary, parent: VBoxContainer) -> HBoxContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size.y = 110
	var skin := StyleBoxTexture.new()
	skin.texture = load(UI + "slotAmici.png")
	# The row uses the same aspect ratio as the supplied artwork.
	skin.content_margin_left = 28
	skin.content_margin_right = 38
	skin.content_margin_top = 12
	skin.content_margin_bottom = 12
	tile.add_theme_stylebox_override("panel", skin)
	parent.add_child(tile)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 20)
	tile.add_child(line)
	var dot := TextureRect.new()
	dot.texture = load(UI + ("amicoOn.png" if row.get("online", false) else "amicoOff.png"))
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.custom_minimum_size = Vector2(34, 34)
	dot.size_flags_vertical = SIZE_SHRINK_CENTER
	dot.tooltip_text = "Online di recente" if row.get("online", false) else "Offline"
	line.add_child(dot)
	var portrait := PanelContainer.new()
	portrait.custom_minimum_size = Vector2(78, 78)
	portrait.size_flags_vertical = SIZE_SHRINK_CENTER
	var portrait_skin := StyleBoxFlat.new()
	portrait_skin.bg_color = Color("d8ddd9")
	portrait_skin.border_color = Color("102a2c")
	portrait_skin.set_border_width_all(3)
	portrait_skin.set_corner_radius_all(39)
	portrait.add_theme_stylebox_override("panel", portrait_skin)
	line.add_child(portrait)
	var encoded := str(row.get("avatar", "") if row.get("avatar") != null else "")
	var texture := preload("res://scenes/balatro/scripts/avatar_data.gd").circular_texture(encoded)
	if texture != null:
		portrait_skin.bg_color = Color.TRANSPARENT
		var photo := TextureRect.new()
		photo.name = "FriendPhoto"
		photo.texture = texture
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.add_child(photo)
	var name_text := str(row.get("username", "") if row.get("username") != null else "")
	var identity_rows := VBoxContainer.new()
	identity_rows.name = "Identity"
	identity_rows.size_flags_horizontal = SIZE_EXPAND_FILL
	identity_rows.size_flags_vertical = SIZE_SHRINK_CENTER
	identity_rows.add_theme_constant_override("separation", 0)
	line.add_child(identity_rows)
	# One rich line keeps the code adjacent to the name, not right-aligned.
	var name_line := RichTextLabel.new()
	identity_rows.add_child(name_line)
	name_line.custom_minimum_size.y = 36
	name_line.fit_content = false
	name_line.scroll_active = false
	name_line.add_theme_font_override("normal_font", menu.KIDS_FONT)
	name_line.add_theme_font_size_override("normal_font_size", 28)
	name_line.push_color(Color("faf6ff"))
	name_line.add_text(name_text if not name_text.is_empty() else "Giocatore")
	name_line.pop()
	name_line.push_color(Color("bda0ee"))
	name_line.add_text("  #" + str(row.get("public_id", "")))
	name_line.pop()
	name_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

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
	var scroll := preload("res://scenes/balatro/scripts/touch_scroll.gd").new()
	add_child(scroll)
	scroll.position = at
	scroll.size = Vector2(750,620)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var box := VBoxContainer.new()
	box.size_flags_horizontal = SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",14)
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
	var response: Dictionary = await manager.call_api("bisca_search_friends_with_avatars", {"query":search_text})
	if not response.ok:
		response = await manager.call_api("bisca_search_friends", {"query":search_text})
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
		var line := contact_tile(row, results)
		action_button(line, "+", act.bind(str(row.id), "request"), "Aggiungi amico")

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
	if manager.entries.is_empty():
		var empty := label("Non hai ancora amici. Cerca un nome o un #codice.", contacts)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.y = 130
	for row in manager.entries:
		var line := contact_tile(row, contacts)
		var identity_rows := line.get_node("Identity")
		if row.status == "accepted" and not row.has("invite_code"):
			action_button(line, "×", _ask_remove_friend.bind(str(row.id), manager.display_name(row)), "Rimuovi amico")
		if row.has("invite_code"):
			var invite := label("Ti ha invitato in lobby", identity_rows)
			invite.add_theme_font_size_override("font_size", 22)
			invite.add_theme_color_override("font_color", Color("bda0ee"))
			action_button(line, "×", answer_invite.bind(str(row.id), false), "Rifiuta invito")
			action_button(line, "✓", answer_invite.bind(str(row.id), true), "Accetta invito", true)
		elif row.status != "accepted":
			var status_label := label("Richiesta ricevuta" if row.incoming else "Richiesta inviata", identity_rows)
			status_label.add_theme_font_size_override("font_size", 22)
			status_label.add_theme_color_override("font_color", Color("bda0ee"))
			if row.incoming:
				action_button(line, "×", act.bind(str(row.id), "decline"), "Rifiuta richiesta")
				action_button(line, "✓", act.bind(str(row.id), "accept"), "Accetta richiesta", true)
			else:
				action_button(line, "ANNULLA", act.bind(str(row.id), "cancel"), "Annulla richiesta")
	if not manager.error.is_empty():
		notice.text = manager.error
