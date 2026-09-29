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
var search_box: Panel

func setup(host: Control) -> void:
	menu = host
	manager = get_node("/root/FriendsManager")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back: Button = menu._button(self, "INDIETRO", menu.show_home)
	back.position = Vector2(40,40)
	back.size = Vector2(260,96)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var skin := back.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		skin.set_corner_radius_all(48)
		back.add_theme_stylebox_override(state,skin)
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
	query.placeholder_text = "Username completo o #codice"
	query.max_length = 64
	query.add_theme_font_size_override("font_size",30)
	query.text_submitted.connect(func(_text): search())
	var search_button: Button = menu._button(self,"CERCA",search)
	search_button.position = Vector2(1260,180)
	search_button.size = Vector2(300,70)
	notice = label("",self)
	notice.position = Vector2(180,270)
	notice.size = Vector2(1560,90)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	results = column(Vector2(180,380))
	contacts = column(Vector2(990,380))
	var friends_box := Panel.new()
	add_child(friends_box)
	friends_box.position = Vector2(180,230)
	friends_box.size = Vector2(1500,750)
	friends_box.add_theme_stylebox_override("panel",Style.button_style(Style.PANEL,Style.HOVER,4))
	var contacts_scroll := contacts.get_parent() as ScrollContainer
	contacts_scroll.reparent(friends_box)
	contacts_scroll.position = Vector2(24,24)
	contacts_scroll.size = Vector2(1452,702)
	search_box = Panel.new()
	add_child(search_box)
	search_box.position = Vector2(980,330)
	search_box.size = Vector2(780,650)
	search_box.z_index = 10
	search_box.add_theme_stylebox_override("panel",Style.button_style(Style.PANEL,Style.HOVER,4))
	query.reparent(search_box)
	query.position = Vector2(24,24)
	query.size = Vector2(732,70)
	search_button.reparent(search_box)
	search_button.position = Vector2(24,110)
	search_button.size = Vector2(340,70)
	var close: Button = menu._button(search_box,"CHIUDI",func(): search_box.hide())
	close.position = Vector2(392,110)
	close.size = Vector2(364,70)
	var results_scroll := results.get_parent() as ScrollContainer
	results_scroll.reparent(search_box)
	results_scroll.position = Vector2(24,204)
	results_scroll.size = Vector2(732,422)
	search_box.hide()
	var add_button: Button = menu._round_icon_button(self,"add_friends.svg","Aggiungi amici",func(): search_box.show(); query.grab_focus())
	add_button.position = Vector2(1740,230)
	add_button.size = Vector2.ONE * menu.ROUND_BUTTON_SIZE
	notice.position = Vector2(180,150)
	notice.size = Vector2(1450,70)
	manager.changed.connect(update_contacts)
	get_node("/root/AccountSession").changed.connect(_identity_changed)
	identity = str(get_node("/root/AccountSession").user_id)
	update_contacts()

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
	clear(results)
	query.clear()

func open() -> void:
	search_box.hide()
	manager.refresh()
	update_contacts()

func search() -> void:
	if working: return
	if query.text.strip_edges().length() < 3:
		notice.text = "Inserisci almeno 3 caratteri."
		return
	working = true
	var generation := search_generation
	var response: Dictionary = await manager.call_api("bisca_search_friends", {"query":query.text.strip_edges()})
	working = false
	if generation != search_generation: return
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

func act(target: String, action: String) -> void:
	if working: return
	working = true
	var generation := search_generation
	var response: Dictionary = await manager.call_api("bisca_friend_action",{"target":target,"action":action})
	working = false
	if generation != search_generation: return
	notice.text = "Operazione completata." if response.ok else response.message
	manager.refresh()

func answer_invite(sender: String, accept: bool) -> void:
	if working:
		return

	var net := get_node("/root/NetworkSession")

	# room_code può rimanere valorizzato per il rejoin anche quando
	# il giocatore non si trova realmente dentro una lobby.
	# Consideriamo attiva la lobby solo quando esiste anche uno
	# stato server valido relativo allo stesso codice stanza.
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
		if row.has("invite_code"):
			label("Invito alla lobby " + str(row.invite_code),identity_rows)
			for accept in [true,false]:
				var invitation_button: Button = menu._button(line,"ACCETTA" if accept else "RIFIUTA",answer_invite.bind(str(row.id),accept))
				invitation_button.custom_minimum_size = Vector2(210,60)
				invitation_button.size_flags_vertical = SIZE_SHRINK_CENTER
		if row.status != "accepted":
			label("Richiesta ricevuta" if row.incoming else "Richiesta inviata",identity_rows)
			var actions := ["accept","decline"] if row.incoming else ["cancel"]
			for action in actions:
				var button: Button = menu._button(line,{"accept":"ACCETTA","decline":"RIFIUTA","cancel":"ANNULLA"}[action],act.bind(str(row.id),action))
				button.custom_minimum_size = Vector2(210,60)
				button.size_flags_vertical = SIZE_SHRINK_CENTER
	if not manager.error.is_empty(): notice.text = manager.error
