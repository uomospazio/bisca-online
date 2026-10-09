extends Control
signal action_completed(action: String)
## UI account distinta dal profilo temporaneo delle lobby.

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const GenericSkin = preload("res://scenes/balatro/scripts/generic_ui_skin.gd")

var account: Node
var menu: Control
var rows: VBoxContainer
var notice: Label
var address: LineEdit
var password: LineEdit
var confirmation: CheckBox
var buttons: Array[Button] = []
var working := false
var mode := ""
var username_field: LineEdit
var direct_action := false
var provider_intent := ""
var panel: PanelContainer
var scalable_font: FontFile

func setup(host: Control, initial_mode: String = "home") -> void:
	direct_action = initial_mode != "home"
	menu = host
	account = get_node("/root/AccountSession")

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100

	set_meta("cartoon_style_children_excluded", true)
	# Transparent input blocker: modal interaction without the dark rectangle.
	var blocker := Control.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(blocker)
	scalable_font = FONT.duplicate() as FontFile
	scalable_font.multichannel_signed_distance_field = true
	scalable_font.msdf_size = 64
	panel = PanelContainer.new()
	add_child(panel)
	panel.size = Vector2(900, 680)
	GenericSkin.apply(panel, false, 44.0)
	get_viewport().size_changed.connect(_fit_panel)
	_fit_panel.call_deferred()

	var scroll := preload("res://scenes/balatro/scripts/touch_scroll.gd").new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override(
		"separation",
		16
	)

	scroll.add_child(rows)

	account.changed.connect(_account_changed)

	var cloud := get_node("/root/AccountProfile")
	cloud.changed.connect(_account_changed)

	if initial_mode.begins_with("signin_"):
		provider_intent = "login"
		_show(initial_mode.trim_prefix("signin_"))
	else:
		_show(initial_mode)


func _account_changed() -> void:
	if not working and mode == "home":
		_show("home")


func _reconnect() -> void:
	if working:
		return

	working = true

	for button in buttons:
		button.disabled = true

	if is_instance_valid(notice):
		notice.text = "SINCRONIZZAZIONE..."

	await account.connect_account()

	var cloud := get_node("/root/AccountProfile")
	cloud._loaded = false
	await cloud.sync()

	working = false
	_show("home")


func _text(
	value: String,
	size_value := 24
) -> Label:

	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	label.add_theme_font_override("font", scalable_font)
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", Style.TEXT)

	rows.add_child(label)
	return label


func _field(
	placeholder: String,
	secret := false
) -> LineEdit:

	var field := LineEdit.new()

	field.placeholder_text = placeholder
	field.secret = secret
	field.custom_minimum_size.y = 60
	field.max_length = 254

	field.virtual_keyboard_type = (
		LineEdit.KEYBOARD_TYPE_PASSWORD
		if secret
		else LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	)

	field.add_theme_font_size_override("font_size", 28)
	field.add_theme_color_override("font_color", Color("f3effe"))
	field.add_theme_color_override("font_placeholder_color", Color("aaa3be"))

	field.add_theme_stylebox_override(
		"normal",
		Style.button_style(Style.NORMAL)
	)

	field.add_theme_stylebox_override(
		"focus",
		Style.button_style(
			Style.NORMAL,
			Style.HOVER,
			3
		)
	)

	rows.add_child(field)
	return field


func _button(
	text: String,
	action: Callable
) -> Button:

	var button := Button.new()
	rows.add_child(button)
	button.text = text
	button.pressed.connect(action)
	preload("res://scenes/balatro/scripts/button_audio.gd").attach(button)
	button.custom_minimum_size = Vector2(320, 92)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override("font", scalable_font)
	button.add_theme_font_size_override("font_size", 22)
	GenericSkin.apply(button, true)
	# Long captions can grow while preserving the 160:46 aspect ratio.
	var width := maxf(320, scalable_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 32)
	button.custom_minimum_size = Vector2(width, width / GenericSkin.BUTTON_RATIO)

	buttons.append(button)

	return button


func _show(next: String) -> void:
	if direct_action and next == "home":
		queue_free()
		return
	mode = next

	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()

	buttons.clear()

	_text("CREA NUOVO ACCOUNT" if mode == "new_guest" else "ACCOUNT", 44)

	if mode == "home":
		provider_intent = ""
		_button("SALVA I TUOI PROGRESSI", func(): _show("save_providers"))
		_button("ACCEDI", func(): _show("login_providers"))
	elif mode in ["save_providers", "login_providers"]:
		provider_intent = "save" if mode == "save_providers" else "login"
		_text("SALVA I TUOI PROGRESSI" if provider_intent == "save" else "ACCEDI")
		_button("APPLE", func(): _show("apple"))
		_button("GOOGLE", func(): _show("google"))
		_button("EMAIL", _choose_email)
	elif mode == "social":
		_button("APPLE", func(): _show("apple"))
		_button("GOOGLE", func(): _show("google"))
	elif mode in ["apple", "google"]:
		_text(("COLLEGA " if provider_intent == "save" else "ACCEDI CON ") + mode.to_upper())
		if provider_intent == "save":
			_text("Collega questo profilo per conservare i tuoi progressi.")
			_button("CONTINUA", func(): _run_social(true))
		elif provider_intent == "login":
			_text("Accedi a un account esistente. I progressi del profilo attuale non vengono uniti.")
			_button("CONTINUA", func(): _run_social(false))
		else:
			_text("Collega per mantenere questo profilo e i progressi, oppure accedi a un account esistente.")
			_button("COLLEGA QUESTO ACCOUNT", func(): _run_social(true))
			_button("ACCEDI A UN ALTRO ACCOUNT", func(): _run_social(false))
	elif mode.begins_with("connected_"):
		var provider := mode.trim_prefix("connected_")
		_text(provider.to_upper() + " CONNESSO", 32)
		_text(str(account.provider_accounts.get(provider, "Account collegato")))
		_button("MODIFICA USERNAME", func(): _show("username"))
		if provider == "email" and account.email_verified:
			_button("IMPOSTA PASSWORD", func(): _show("password"))
		_button("CONTINUA CON UN ALTRO ACCOUNT", func(): _show("new_guest"))
	elif mode == "email_saved":
		_text("I tuoi progressi sono già collegati a " + account.email + ".")
	elif mode == "username":
		_text("Username account: 3–24 caratteri, lettere, numeri, punto o underscore. Vuoto = solo codice.")
		username_field = _field("Username")
		username_field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
		username_field.max_length = 24
		var saved = get_node("/root/AccountProfile").profile.get("username")
		username_field.text = str(saved) if saved != null else ""
		_button("SALVA USERNAME", func(): _run("username"))

	elif mode == "link":
		_text(
			"Collega la tua email all'ospite: il profilo e il mazzo rimangono gli stessi."
		)

		address = _field("Email")
		address.text = account.pending_email

		_button(
			"INVIA EMAIL DI CONFERMA",
			func():
				_run("link")
		)

	elif mode == "verify":
		_text(
			"Apri l'email inviata a "
			+ account.pending_email
			+ ". Premi il link di conferma, poi torna qui senza chiudere o cancellare i dati di BISCA."
		)

		_text(
			"Dopo la conferma potrai scegliere la password. Controlla anche lo spam.",
			20
		)

		_button(
			"HO CONFERMATO L'EMAIL",
			func():
				_run("verify")
		)

		_button(
			"INVIA DI NUOVO / CAMBIA EMAIL",
			func():
				_show("link")
		)

	elif mode == "password":
		_text(
			"Email verificata. Scegli una password di almeno 8 caratteri per recuperare questo account."
		)

		password = _field(
			"Password",
			true
		)

		_button(
			"SALVA PASSWORD",
			func():
				_run("password")
		)

	elif mode == "login":
		_text(
			"Accedi al profilo esistente. I dati dell'ospite NON vengono uniti. Se vuoi conservarlo, collega prima la sua email."
		)

		address = _field("Email")

		password = _field(
			"Password",
			true
		)

		confirmation = CheckBox.new()
		confirmation.text = "Confermo il cambio di account"
		confirmation.add_theme_font_size_override("font_size", 26)
		rows.add_child(confirmation)

		_button(
			"ACCEDI",
			func():
				_run("login")
		)

	elif mode == "new_guest":
		_text("Se l'account attuale non è collegato potresti non poterlo più recuperare.")
		_button("CONFERMA", func(): _run("new_guest"))

	elif mode == "logout":
		_text(
			"Uscire da questo account? I dati cloud restano salvati. Verra' creato un nuovo ospite; per recuperare questo profilo serviranno email e password."
		)

		_button(
			"CONFERMA USCITA",
			func():
				_run("logout")
		)

	notice = _text(
		"",
		22
	)

	_button(
		"CHIUDI"
		if mode == "home"
		else "INDIETRO",

		func():
			if mode == "home":
				queue_free()
			else:
				_go_back()
	)
	if mode == "home":
		_layout_home()
	elif mode == "new_guest":
		var material: ShaderMaterial = buttons.back().get_meta("generic_ui_material")
		material.set_shader_parameter("fill_top", Color("88302c"))
		material.set_shader_parameter("fill_bottom", Color("5d1f25"))
		material.set_shader_parameter("border_top", Color("e96872"))
		material.set_shader_parameter("border_bottom", Color("953143"))
	_fit_panel.call_deferred()

func _layout_home() -> void:
	var title := rows.get_child(0) as Label
	title.hide()
	notice.hide()
	var content := Control.new()
	rows.add_child(content)
	content.custom_minimum_size = Vector2(812, 400)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.reparent(content, false)
	title.show()
	title.position = Vector2(0, -8)
	title.size = Vector2(812, 116)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 92)
	buttons[0].text = "SALVA\nPROGRESSI"
	for index in buttons.size():
		var button := buttons[index]
		button.reparent(content, false)
		var width := 368.0 if index < 2 else 320.0
		button.custom_minimum_size = Vector2(width, width / GenericSkin.BUTTON_RATIO)
		button.size = button.custom_minimum_size
		button.position = Vector2(12 + index * 420, 160) if index < 2 else Vector2(246, 310)
		button.add_theme_font_size_override("font_size", 40)


func _run_social(link_current: bool) -> void:
	if working:
		return
	working = true
	var social := account.get_node("SocialAuth")
	for button in buttons:
		button.disabled = true
	notice.text = "Completa l'accesso nel browser."
	var cancel_button := _button("ANNULLA ACCESSO", social.cancel)
	social.completed.connect(func(result: Dictionary):
		working = false
		buttons.erase(cancel_button)
		cancel_button.queue_free()
		for button in buttons:
			button.disabled = false
		if result.get("ok", false):
			action_completed.emit("social")
			_show("home")
		else:
			notice.text = str(result.get("message", "Accesso non riuscito."))
	, CONNECT_ONE_SHOT)
	social.start(mode, link_current)

func _run(action: String) -> void:
	if working:
		return

	if (
		action in ["link", "login"]
		and (
			not "@" in address.text
			or address.text.strip_edges().is_empty()
		)
	):
		notice.text = "Inserisci un indirizzo email valido."
		return

	if (
		action == "login"
		and not confirmation.button_pressed
	):
		notice.text = "Conferma il cambio account prima di accedere."
		return

	working = true

	for button in buttons:
		button.disabled = true

	notice.text = "ATTENDI..."

	var result: Dictionary

	match action:
		"new_guest":
			result = await account.continue_as_new_guest()
		"username":
			result = await get_node("/root/AccountProfile").save_username(username_field.text)
		"link":
			result = await account.link_email(address.text)
		"verify":
			result = await account.check_email_confirmation()
		"password":
			result = await account.set_password(password.text)
		"login":
			result = await account.sign_in(address.text, password.text)
		"logout":
			result = await account.sign_out()

	if is_instance_valid(password):
		password.clear()

	working = false

	if not result.ok:
		for button in buttons:
			button.disabled = false

		notice.text = result.get(
			"message",
			"Operazione non riuscita."
		)
		return

	action_completed.emit(action)
	_show(
		"verify"
		if action == "link"
		else (
			"password"
			if action == "verify"
			else "home"
		)
	)

	notice.text = (
		"Email inviata. Apri il link di conferma."
		if action == "link"
		else "Operazione completata."
	)

func _choose_email() -> void:
	if provider_intent == "login":
		_show("login")
	elif not account.pending_email.is_empty():
		_show("verify")
	elif account.email_verified and not account.password_ready:
		_show("password")
	elif account.password_ready:
		_show("email_saved")
	else:
		_show("link")

func _go_back() -> void:
	if mode in ["save_providers", "login_providers"]:
		_show("home")
	elif not provider_intent.is_empty():
		_show("save_providers" if provider_intent == "save" else "login_providers")
	else:
		_show("home")

func _fit_panel() -> void:
	if not is_instance_valid(panel): return
	var viewport_size := get_viewport_rect().size
	var safe := Rect2(Vector2.ZERO, viewport_size)
	if OS.has_feature("mobile"):
		var window := get_window()
		var physical := Rect2(DisplayServer.get_display_safe_area()).intersection(Rect2(Vector2(window.position), Vector2(window.size)))
		if physical.has_area():
			var ratio := viewport_size / Vector2(window.size)
			safe = Rect2((physical.position - Vector2(window.position)) * ratio, physical.size * ratio)
	var bounds: Rect2 = get_global_transform_with_canvas().affine_inverse() * safe
	bounds = bounds.grow(-40)
	var height := 508.0 if mode == "home" else 760.0
	panel.size = Vector2(900, height)
	var factor := minf(1.0, minf(bounds.size.x / panel.size.x, bounds.size.y / panel.size.y))
	panel.scale = Vector2.ONE * factor
	panel.position = bounds.get_center() - panel.size * factor / 2
