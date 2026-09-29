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
	var title := label("AMICI", self)
	title.position = Vector2(860,55)
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

func update_contacts() -> void:
	clear(contacts)
	label("AMICI E RICHIESTE",contacts)
	for row in manager.entries:
		label(manager.display_name(row),contacts)
		if row.status == "accepted":
			label("AMICO",contacts)
		else:
			label("Richiesta ricevuta" if row.incoming else "Richiesta inviata",contacts)
			var actions := ["accept","decline"] if row.incoming else ["cancel"]
			for action in actions:
				var button: Button = menu._button(contacts,{"accept":"ACCETTA","decline":"RIFIUTA","cancel":"ANNULLA"}[action],act.bind(str(row.id),action))
				button.custom_minimum_size = Vector2(0,60)
	if not manager.error.is_empty(): notice.text = manager.error
