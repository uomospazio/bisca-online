extends Control
signal action_completed(action: String)
## UI account distinta dal profilo temporaneo delle lobby.

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")

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

func setup(host: Control, initial_mode: String = "home") -> void:
	direct_action = initial_mode != "home"
	menu = host
	account = get_node("/root/AccountSession")

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100

	var shade := ColorRect.new()
	# Overlay coerente con il fondo dark del menu: il nero opaco rende visibile
	# il rettangolo dell'area logica 1920x1080 sui display piu' larghi.
	shade.color = Color("171324", 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := PanelContainer.new()
	add_child(panel)

	panel.position = Vector2(460, 120)
	panel.size = Vector2(1000, 840)

	var skin := Style.button_style(
		Style.PANEL,
		Style.HOVER,
		4
	)

	for edge in ["left", "right", "top", "bottom"]:
		skin.set(
			"content_margin_" + edge,
			28.0
		)

	panel.add_theme_stylebox_override(
		"panel",
		skin
	)

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

	label.add_theme_font_override("font", FONT)
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

	var button: Button = menu._button(
		rows,
		text,
		action
	)

	button.custom_minimum_size = Vector2(
		0,
		60
	)

	# Altezza 60 px -> radius Y/2 = 30 px.
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var base_style := button.get_theme_stylebox(state)
		if base_style is StyleBoxFlat:
			var style := (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
			style.set_corner_radius_all(30)
			button.add_theme_stylebox_override(state, style)

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

	_text("ACCOUNT", 44)

	if mode == "home":

		_text(
			"OSPITE - SOLO SU QUESTO DISPOSITIVO"
			if account.anonymous
			else "EMAIL: " + account.email
		)

		var cloud := get_node("/root/AccountProfile")
		var display_name: String = cloud.account_display_name()
		if not display_name.is_empty():
			_text("PROFILO: " + display_name)
		var username_button := _button("MODIFICA USERNAME", func(): _show("username"))
		var dot: Panel = menu._notification_dot(username_button)
		dot.visible = cloud.needs_username()

		if cloud.profile.has("public_id"):
			var public_id := str(
				cloud.profile.get(
					"public_id",
					""
				)
			)

			if (
				not public_id.is_empty()
				and public_id != "<null>"
			):
				_text(
					"ID BISCA: #" + public_id,
					24
				)

		_text(
			"SALVATAGGIO MAZZO: " +
			(
				"IN ATTESA / OFFLINE"
				if (
					not account.is_authenticated()
					or not cloud.last_error.is_empty()
					or cloud._pending
					or not cloud._loaded
				)
				else "SINCRONIZZATO"
			),
			20
		)

		_text(
			"Nome e foto della lobby rimangono separati. Qui salvi e recuperi l'account.",
			20
		)

		if not account.password_ready:
			_button(
				"SALVA I TUOI PROGRESSI",
				func():
					_show(
						"password"
						if account.email_verified
						else "link"
					)
			)

		if not account.pending_email.is_empty():
			_button(
				"HO CONFERMATO L'EMAIL",
				func():
					_show("verify")
			)

		_button(
			"ACCEDI A UN ACCOUNT",
			func():
				_show("login")
		)

		_button("CONTINUA CON UN NUOVO OSPITE", func(): _show("new_guest"))

		_button(
			"RICONTROLLA CONNESSIONE",
			_reconnect
		)

		if (
			not account.anonymous
			and (account.password_ready or account.social_ready)
		):
			_button(
				"ESCI DALL'ACCOUNT",
				func():
					_show("logout")
			)

	elif mode == "social":
		_button("APPLE", func(): _show("apple"))
		_button("GOOGLE", func(): _show("google"))
	elif mode in ["apple", "google"]:
		_text("ACCEDI CON " + mode.to_upper())
		_text("Collega per mantenere questo profilo e i progressi. Accedi a un altro account per recuperarne uno esistente: i profili non vengono uniti.")
		_button("COLLEGA QUESTO ACCOUNT", func(): _run_social(true))
		_button("ACCEDI A UN ALTRO ACCOUNT", func(): _run_social(false))
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
		_text("Creare un nuovo ospite separato? L'account precedente resta nel cloud: se collegato, puoi recuperarlo con email e password. Monete e oggetti NON vengono trasferiti.")
		_text("Se il precedente account era un ospite senza email, potresti non poterlo piu' recuperare da questo dispositivo.", 22)
		confirmation = CheckBox.new()
		confirmation.text = "Confermo di voler cambiare account"
		confirmation.add_theme_font_size_override("font_size", 26)
		rows.add_child(confirmation)
		_button("CREA NUOVO OSPITE", func(): _run("new_guest"))

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
				_show("home")
	)


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
		action in ["login", "new_guest"]
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
