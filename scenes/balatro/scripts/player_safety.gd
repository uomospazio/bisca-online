extends Node
## Only server-verified account IDs identify a player; names and pictures can change.
var account_id := ""
var blocked := {}
var loaded := false
var revision := 0
var sheet: AcceptDialog
var account: Node
var net: Node

func _ready() -> void:
	account = get_node("/root/AccountSession")
	net = get_node("/root/NetworkSession")
	account.changed.connect(_identity_changed)
	net.connection_lost.connect(_close)
	_identity_changed()

func _identity_changed() -> void:
	var id := str(account.user_id) if account.is_authenticated() else ""
	if id == account_id: return
	_close()
	account_id = id
	blocked.clear()
	loaded = false
	revision += 1
	_refresh_voice()
	if not account_id.is_empty(): _load_blocks(revision)

func _load_blocks(generation: int) -> void:
	var result: Dictionary = await get_node("/root/FriendsManager").call_api("bisca_list_blocks")
	if generation != revision: return
	if result.ok and result.data is Array:
		for row in result.data:
			blocked[str(row.id)] = true
		loaded = true
		_refresh_voice()
	else:
		await get_tree().create_timer(15).timeout
		if generation == revision: _load_blocks(generation)

func allow_voice(id: String) -> bool:
	return id.is_empty() or (loaded and not blocked.has(id))

func _refresh_voice() -> void:
	if net != null and not net.latest.get("people", []).is_empty():
		get_node("/root/VoiceChat")._on_network_updated(net.latest)

func _t(it: String, en: String) -> String:
	return en if get_node("/root/GameSettings").values.language == "en" else it

func _close() -> void:
	if is_instance_valid(sheet):
		sheet.hide()
		sheet.queue_free()
	sheet = null

func _dialog(title: String, body: String = "") -> AcceptDialog:
	_close()
	sheet = AcceptDialog.new()
	add_child(sheet)
	sheet.exclusive = true
	sheet.title = title
	sheet.dialog_text = body
	sheet.confirmed.connect(_close)
	sheet.canceled.connect(_close)
	return sheet

func open_slot(slot: int) -> void:
	var people: Array = net.latest.get("people", [])
	if slot < 0 or slot >= people.size() or slot == int(net.latest.get("you", -1)): return
	var person: Dictionary = people[slot]
	if person.get("bot", true): return
	var id := str(person.get("account_id", ""))
	var name_text := str(person.get("name", ""))
	var room := str(net.room_code)
	var dialog := _dialog(_t("Giocatore", "Player"))
	var box := VBoxContainer.new()
	dialog.add_child(box)
	var portrait := TextureRect.new()
	box.add_child(portrait)
	portrait.texture = net.avatar_for_slot(slot)
	portrait.custom_minimum_size = Vector2(100,100)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var label := Label.new()
	box.add_child(label)
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = name_text
	if account_id.is_empty() or id.is_empty():
		var unavailable := Label.new()
		box.add_child(unavailable)
		unavailable.text = _t("Identità online non disponibile.", "Online identity unavailable.")
	elif id != account_id:
		_action(box, _t("Segnala giocatore", "Report player"), _report_menu.bind(id,name_text,room))
		var block := _action(box, _t("Blocca giocatore", "Block player"), _confirm_block.bind(id,name_text))
		if blocked.has(id):
			block.disabled = true
			block.text = _t("Giocatore bloccato", "Player blocked")
	dialog.popup_centered()

func _action(parent: Control, caption: String, fn: Callable) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.text = caption
	button.custom_minimum_size = Vector2(320,58)
	button.pressed.connect(fn)
	return button

func _report_menu(id: String, name_text: String, room: String) -> void:
	var dialog := _dialog(_t("Segnala giocatore", "Report player"))
	var box := VBoxContainer.new()
	dialog.add_child(box)
	var reason := OptionButton.new()
	box.add_child(reason)
	for label in [_t("Abuso in chat vocale","Voice abuse"), _t("Nome o foto inappropriati","Inappropriate name or photo"), _t("Altro","Other")]:
		reason.add_item(label)
	_action(box,_t("Invia segnalazione","Send report"),func():
		_submit("bisca_report_player",{"target":id,"category":["voice","profile","other"][reason.selected],"displayed_name":name_text,"room_code":room}))
	dialog.get_ok_button().text = _t("Annulla","Cancel")
	dialog.popup_centered()

func _confirm_block(id: String, name_text: String) -> void:
	var dialog := _dialog(_t("Bloccare %s?", "Block %s?") % name_text,
		_t("Non sentirai più la sua voce. Non potrete scambiarvi inviti o richieste di amicizia.",
		"You will no longer hear this player. Neither of you can send the other invites or friend requests."))
	dialog.get_ok_button().text = _t("Annulla","Cancel")
	dialog.add_button(_t("Blocca","Block"),true,"block")
	dialog.custom_action.connect(func(_action_name): _submit("bisca_block_player",{"target":id}))
	dialog.popup_centered()

func _submit(endpoint: String, payload: Dictionary) -> void:
	var generation := revision
	var progress := _dialog(_t("Attendi…","Please wait…"))
	progress.popup_centered()
	var result: Dictionary = await get_node("/root/FriendsManager").call_api(endpoint,payload)
	if generation != revision: return
	var is_block := endpoint == "bisca_block_player"
	if result.ok and is_block:
		blocked[str(payload.target)] = true
		_refresh_voice()
	if not is_instance_valid(progress) or sheet != progress: return
	var message := _t("Operazione non riuscita. Riprova.","Could not complete this action. Try again.")
	if result.ok:
		message = _t("Giocatore bloccato.","Player blocked.") if is_block else _t("Segnalazione inviata.","Report sent.")
	_dialog(_t("Sicurezza","Safety"),message).popup_centered()
