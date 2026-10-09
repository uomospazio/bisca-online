extends Control

const SAVE := "user://welcome.cfg"
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
var menu: Control
var account: Node
var cloud: Node
var config := ConfigFile.new()
var column: VBoxContainer
var notice: Label
var username: LineEdit
var guest := false
var working := false
var syncing := false
var controls: Array[Button] = []
var intro_art: Control

func setup(host: Control) -> void:
	menu = host
	account = get_node("/root/AccountSession")
	cloud = get_node("/root/AccountProfile")
	config.load(SAVE)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 90
	cloud.changed.connect(_sync_pending_name)
	cloud.changed.connect(_refresh_username)
	# Gli account email già salvati continuano a ripristinare la sessione:
	# non devono scegliere un nuovo ospite né rifare l'accesso ad ogni avvio.
	if not account.user_id.is_empty() and (account.password_ready or account.social_ready) and not bool(config.get_value("welcome", "completed", false)):
		hide()
		return
	if bool(config.get_value("welcome", "completed", false)):
		var saved_name := str(config.get_value("welcome", "name", ""))
		if str(config.get_value("welcome", "owner", "")) == str(account.user_id):
			_set_home_name(saved_name)
		hide()
		if account.user_id.is_empty():
			account.connect_account()
		_sync_pending_name()
		return
	menu.menu_content.hide()
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column = VBoxContainer.new()
	column.custom_minimum_size.x = 1000
	column.add_theme_constant_override("separation", 32)
	center.add_child(column)
	_choices()

func _clear() -> void:
	if is_instance_valid(intro_art):
		remove_child(intro_art)
		intro_art.queue_free()
		intro_art = null
	column.show()
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	controls.clear()
	var logo := TextureRect.new()
	logo.texture = preload("res://scenes/balatro/trick_asset/ui_bisca/logo.svg")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(620, 230)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(logo)

func _button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = menu._button(parent, text, action)
	button.custom_minimum_size = Vector2(300, 90)
	button.add_theme_font_size_override("font_size", 32)
	preload("res://scenes/balatro/scripts/generic_ui_skin.gd").apply(button, true)
	controls.append(button)
	return button

func _text(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 28)
	column.add_child(label)
	return label

func _choices() -> void:
	_clear()
	column.hide()
	intro_art = preload("res://scenes/balatro/scripts/intro_art_ui.gd").new()
	add_child(intro_art)
	intro_art.setup_intro(self)
	notice = intro_art.notice
	controls.assign(intro_art.buttons)

func _continue_guest() -> void:
	if account.is_authenticated() and not account.anonymous:
		notice.text = "Hai già un account collegato. Usa Email per accedere senza perdere i progressi."
		return
	guest = true
	if not account.is_authenticated():
		account.connect_account()
	_name_page()

func _social_choices(provider: String) -> void:
	_clear()
	_text("ACCEDI CON " + provider.to_upper())
	if not account.user_id.is_empty():
		_text("Collega per mantenere questo profilo e i progressi. Accedi a un altro account per recuperarne uno esistente: i profili non vengono uniti.")
		_button(column, "COLLEGA QUESTO ACCOUNT", func(): _social_start(provider, true))
		_button(column, "ACCEDI A UN ALTRO ACCOUNT", func(): _social_start(provider, false))
	else:
		_button(column, "CONTINUA", func(): _social_start(provider, false))
	_button(column, "INDIETRO", _choices)
	notice = _text("")

func _social_start(provider: String, link_current: bool) -> void:
	var social := account.get_node("SocialAuth")
	for button in controls:
		button.disabled = true
	notice.text = "Completa l'accesso nel browser."
	var cancel_button := _button(column, "ANNULLA ACCESSO", social.cancel)
	var callback := func(result: Dictionary):
		cancel_button.queue_free()
		controls.erase(cancel_button)
		for button in controls:
			button.disabled = false
		if result.get("ok", false):
			guest = false
			_name_page()
		else:
			notice.text = str(result.get("message", "Accesso non riuscito."))
	social.completed.connect(callback, CONNECT_ONE_SHOT)
	social.start(provider, link_current)

func _email_choices() -> void:
	_clear()
	_button(column, "ACCEDI CON EMAIL", func(): _email_form("login"))
	_button(column, "REGISTRATI CON EMAIL", func(): _email_form("link"))
	_button(column, "INDIETRO", _choices)
	notice = _text("")

func _email_form(mode: String) -> void:
	if working:
		return
	working = true
	for button in controls:
		button.disabled = true
	if mode == "link" and not account.is_authenticated():
		notice.text = "Connessione..."
		await account.connect_account()
	working = false
	for button in controls:
		button.disabled = false
	if mode == "link" and not account.is_authenticated():
		notice.text = "Connessione non disponibile. Riprova o continua come ospite."
		return
	var panel := preload("res://scenes/balatro/scripts/account_panel.gd").new()
	add_child(panel)
	panel.setup(menu, mode)
	panel.action_completed.connect(func(action: String):
		if action in ["login", "password"]:
			guest = false
			_name_page()
	)

func _name_page() -> void:
	_clear()
	_text("SCEGLI IL TUO USERNAME")
	username = LineEdit.new()
	username.placeholder_text = "Come ti chiami?"
	username.max_length = 24
	username.custom_minimum_size = Vector2(700, 80)
	username.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	username.alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu._style_input(username, 36)
	var existing = cloud.profile.get("username") if str(cloud.profile.get("id", "")) == str(account.user_id) else null
	username.text = str(existing) if existing != null else ""
	column.add_child(username)
	_button(column, "CONTINUA", _finish)
	_button(column, "INDIETRO", _choices)
	notice = _text("")

func _set_home_name(value: String) -> void:
	menu.name_input.max_length = 24
	menu.name_input.text = value
	menu.account_default_name = value
	menu._refresh_single_profile()

func _refresh_username() -> void:
	# The profile may arrive after OAuth completed; never overwrite typed input.
	if is_instance_valid(username) and username.text.is_empty() and str(cloud.profile.get("id", "")) == str(account.user_id):
		var existing = cloud.profile.get("username")
		if existing != null:
			username.text = str(existing)

func _finish() -> void:
	if working:
		return
	var value := username.text.strip_edges()
	if RegEx.create_from_string("^[A-Za-z0-9_.]{3,24}$").search(value) == null:
		notice.text = "Scegli un username valido di almeno 3 caratteri."
		return
	working = true
	username.editable = false
	for button in controls:
		button.disabled = true
	var saved := false
	if account.is_authenticated():
		var result: Dictionary = await cloud.save_username(value)
		saved = result.get("ok", false)
		if not saved:
			notice.text = str(result.get("message", "Riprova tra poco."))
	elif not guest:
		notice.text = "Connettiti per completare l'accesso."
	working = false
	username.editable = true
	for button in controls:
		button.disabled = false
	if not saved and (account.is_authenticated() or not guest):
		return
	config.set_value("welcome", "completed", true)
	config.set_value("welcome", "name", value)
	config.set_value("welcome", "owner", str(account.user_id))
	config.set_value("welcome", "pending_name", not saved)
	config.save(SAVE)
	_set_home_name(value)
	hide()
	menu.menu_content.show()
	menu._play_home_intro()
	_sync_pending_name()

func _sync_pending_name() -> void:
	if syncing or not bool(config.get_value("welcome", "pending_name", false)) or not account.is_authenticated() or not cloud._loaded:
		return
	var owner := str(config.get_value("welcome", "owner", ""))
	if owner.is_empty() and not account.anonymous:
		return # An offline guest's pending name must not overwrite a social account.
	if not owner.is_empty() and owner != str(account.user_id):
		return
	config.set_value("welcome", "owner", str(account.user_id))
	config.save(SAVE)
	syncing = true
	var result: Dictionary = await cloud.save_username(str(config.get_value("welcome", "name", "")))
	syncing = false
	if result.get("ok", false):
		config.set_value("welcome", "pending_name", false)
		config.save(SAVE)
