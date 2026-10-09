extends Control

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const Audio = preload("res://scenes/balatro/scripts/button_audio.gd")
var settings: Node
var sliders: Dictionary = {}
var numbers: Dictionary = {}
var toggles: Dictionary = {}
var account_dot: Panel
var translations: Array = []
var content_scroll: ScrollContainer
var chapters: VBoxContainer
var language: OptionButton
var reset_dialog: ConfirmationDialog
var mic_test: Node
var mic_meter: ProgressBar
var mic_status: Label
var test_button: Button
var page_title: Label
var settings_panel: PanelContainer
var footer_label: Label
var footer_buttons: HBoxContainer
var push_status: Label
var account_name: Label
var account_id: Label
var save_progress: Button
var privacy_button: Button
var privacy_status: Label
var artwork_ui: Control

func _text(it: String, en: String) -> String:
	return en if settings.values.language == "en" else it

func _translated(node: Node, it: String, en: String, property: String = "text") -> void:
	translations.append([node, property, it, en])
	node.set(property, _text(it, en))

func _tab(it: String, en: String) -> VBoxContainer:
	var section := PanelContainer.new()
	section.name = it
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var background := StyleBoxFlat.new()
	background.bg_color = Color("242039")
	background.set_corner_radius_all(22)
	background.content_margin_left = 32
	background.content_margin_right = 32
	background.content_margin_top = 26
	background.content_margin_bottom = 30
	section.add_theme_stylebox_override("panel", background)
	chapters.add_child(section)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 20)
	section.add_child(rows)
	var heading := _label("", 40)
	_translated(heading, it, en)
	heading.add_theme_color_override("font_color", Color("c7b7ff"))
	rows.add_child(heading)
	var divider := HSeparator.new()
	rows.add_child(divider)
	return rows

func _setting(rows: VBoxContainer, it: String, en: String, key: String, slider := false) -> void:
	if slider:
		_add_slider(rows, it, key)
	else:
		_add_toggle(rows, it, key)
	_translated(rows.get_child(-1).get_child(0), it, en)

func setup(menu: Control, back_action: Callable = Callable(), _multiplayer_settings: bool = false) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings = get_node("/root/GameSettings")
	page_title = _label("", 66)
	_translated(page_title, "SETTINGS", "SETTINGS")
	add_child(page_title)
	page_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_title.add_theme_color_override("font_outline_color", Style.HOVER)
	page_title.add_theme_constant_override("outline_size", 12)
	settings_panel = PanelContainer.new()
	add_child(settings_panel)
	var skin := Style.button_style(Style.PANEL, Style.HOVER, 4)
	skin.content_margin_left = 36
	skin.content_margin_right = 36
	skin.content_margin_top = 28
	skin.content_margin_bottom = 28
	settings_panel.add_theme_stylebox_override("panel", skin)
	content_scroll = preload("res://scenes/balatro/scripts/touch_scroll.gd").new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.follow_focus = true
	settings_panel.add_child(content_scroll)
	chapters = VBoxContainer.new()
	chapters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapters.add_theme_constant_override("separation", 28)
	content_scroll.add_child(chapters)
	var account := _tab("ACCOUNT", "ACCOUNT")
	account_name = _label("")
	account.add_child(account_name)
	account_id = _label("")
	account.add_child(account_id)
	var username_button := _account_action(menu, account, "MODIFICA USERNAME", "EDIT USERNAME", "username", back_action.is_valid())
	account_dot = menu._notification_dot(username_button)
	save_progress = _account_action(menu, account, "SALVA I TUOI PROGRESSI", "SAVE YOUR PROGRESS", "save", back_action.is_valid())
	_account_action(menu, account, "ACCEDI A UN ACCOUNT", "SIGN IN TO AN ACCOUNT", "login", back_action.is_valid())
	_account_action(menu, account, "APPLE / GOOGLE", "APPLE / GOOGLE", "social", back_action.is_valid())
	_account_action(menu, account, "CONTINUA CON UN NUOVO OSPITE", "CONTINUE AS A NEW GUEST", "new_guest", back_action.is_valid())
	get_node("/root/AccountProfile").changed.connect(_refresh_account_dot)
	get_node("/root/AccountSession").changed.connect(_refresh_account_dot)
	_refresh_account_dot()
	var audio := _tab("AUDIO E MICROFONO", "AUDIO AND MICROPHONE")
	_setting(audio, "VOLUME GENERALE", "MASTER VOLUME", "main", true)
	_setting(audio, "EFFETTI", "SOUND EFFECTS", "effects", true)
	var microphone := audio
	_setting(microphone, "MICROFONO ABILITATO", "MICROPHONE ENABLED", "microphone_enabled")
	_setting(microphone, "PREMI PER PARLARE", "PUSH TO TALK", "push_to_talk")
	var hint := _label("", 26)
	_translated(hint, "Tieni premuto V o il pulsante microfono al tavolo per parlare.", "Hold V or the microphone button at the table to talk.")
	microphone.add_child(hint)
	mic_test = preload("res://scenes/balatro/scripts/settings_mic_test.gd").new()
	add_child(mic_test)
	test_button = menu._button(microphone, "", func():
		if mic_test.active: mic_test.stop()
		else: mic_test.start()
	)
	test_button.custom_minimum_size = Vector2(420, 76)
	test_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mic_meter = ProgressBar.new()
	mic_meter.custom_minimum_size.y = 28
	mic_meter.show_percentage = false
	microphone.add_child(mic_meter)
	mic_status = _label("", 26)
	microphone.add_child(mic_status)
	var graphics := _tab("GRAFICA", "GRAPHICS")
	_setting(graphics, "MOVIMENTO CAMERA", "CAMERA MOVEMENT", "camera")
	_setting(graphics, "ANIMAZIONI TESTO", "TEXT ANIMATIONS", "text_animations")
	_setting(graphics, "SCHERMO INTERO", "FULLSCREEN", "fullscreen")
	if OS.get_name() in ["Android", "iOS", "Web"]:
		toggles.fullscreen.disabled = true
		_translated(toggles.fullscreen, "Disponibile nella versione PC", "Available on desktop", "tooltip_text")
	chapters.move_child(graphics.get_parent(), 1)
	_setting(graphics, "MOSTRA OGGETTI LANCIATI", "SHOW THROWN OBJECTS", "show_thrown_objects")
	_setting(account, "NOTIFICHE PUSH", "PUSH NOTIFICATIONS", "push_notifications")
	if OS.get_name() == "iOS" and not get_node("/root/PushNotifications").IOS_PUSH_ENABLED:
		toggles.push_notifications.disabled = true
	if OS.get_name() not in ["Android", "iOS"]:
		toggles.push_notifications.disabled = true
		_translated(toggles.push_notifications, "Disponibili nell'app mobile", "Available in the mobile app", "tooltip_text")
	push_status = _label("", 24)
	push_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	push_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	push_status.text = get_node("/root/PushNotifications").last_message
	account.add_child(push_status)
	get_node("/root/PushNotifications").registration_changed.connect(_on_push_registration_changed)
	var push_note := _label("", 26)
	_translated(push_note, "Al primo avvio ti chiederemo il permesso. Se lo rifiuti, puoi riprovare da qui; potrebbe essere necessario abilitarlo anche nelle impostazioni del dispositivo.", "We will ask for permission the first time. If you decline, you can try again here; you may also need to enable it in your device settings.")
	account.add_child(push_note)

	privacy_button = menu._button(account, "", func():
		get_node("/root/RewardedAds").show_privacy_options()
	)
	_translated(privacy_button, "GESTISCI PRIVACY", "MANAGE PRIVACY")
	privacy_button.custom_minimum_size = Vector2(600, 76)
	privacy_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	privacy_button.add_theme_font_size_override("font_size", 30)
	_set_button_radius(privacy_button, 38)
	privacy_status = _label("", 24)
	privacy_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	privacy_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	account.add_child(privacy_status)
	var rewarded_ads := get_node("/root/RewardedAds")
	rewarded_ads.changed.connect(_sync_privacy)
	_sync_privacy()

	var row := _row(chapters, "")
	_translated(row.get_child(0), "LINGUA", "LANGUAGE")
	language = OptionButton.new()
	language.add_item("Italiano")
	language.add_item("English")
	language.add_theme_font_override("font", FONT)
	language.add_theme_font_size_override("font_size", 32)
	language.custom_minimum_size = Vector2(240, 72)
	row.add_child(language)
	language.item_selected.connect(func(index): settings.set_value("language", "en" if index == 1 else "it"))
	footer_label = _label("", 18)
	_translated(footer_label, "LE MODIFICHE VENGONO SALVATE AUTOMATICAMENTE", "CHANGES ARE SAVED AUTOMATICALLY")
	add_child(footer_label)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_dialog = ConfirmationDialog.new()
	add_child(reset_dialog)
	_translated(reset_dialog, "RIPRISTINA IMPOSTAZIONI", "RESET SETTINGS", "title")
	_translated(reset_dialog, "Ripristinare tutte le impostazioni ai valori predefiniti?", "Restore all settings to their defaults?", "dialog_text")
	_translated(reset_dialog.get_ok_button(), "RIPRISTINA", "RESET")
	_translated(reset_dialog.get_cancel_button(), "ANNULLA", "CANCEL")
	reset_dialog.confirmed.connect(settings.reset_defaults)
	footer_buttons = HBoxContainer.new()
	add_child(footer_buttons)
	footer_buttons.add_theme_constant_override("separation", 30)
	var back: Button = menu._button(footer_buttons, "", back_action if back_action.is_valid() else menu.show_home)
	_translated(back, "INDIETRO", "BACK")
	var reset: Button = menu._button(footer_buttons, "", func(): reset_dialog.popup_centered(Vector2i(640, 200)))
	_translated(reset, "RIPRISTINA", "RESET")
	for button in [back, reset]:
		button.custom_minimum_size = Vector2(320, 80)
		_set_button_radius(button, 40)
	settings.changed.connect(_sync)
	get_viewport().size_changed.connect(_layout_page)
	_layout_page()
	_sync()
	if not back_action.is_valid():
		# Retain the existing settings models and callbacks; the home page uses
		# the new compact artwork while pause retains advanced settings.
		for legacy in [page_title, settings_panel, footer_label, footer_buttons]:
			legacy.hide()
		artwork_ui = preload("res://scenes/balatro/scripts/settings_art_ui.gd").new()
		add_child(artwork_ui)
		artwork_ui.setup_settings(self, menu)

func _layout_page() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	# The menu lives in a centered design canvas; convert screen coordinates
	# to this page's coordinates so the heading cannot move outside the screen.
	var screen_to_page := get_global_transform_with_canvas().affine_inverse()
	var safe := Rect2(Vector2.ZERO, viewport_size)
	if OS.has_feature("mobile"):
		var window := get_window()
		var physical := Rect2(DisplayServer.get_display_safe_area()).intersection(Rect2(Vector2(window.position), Vector2(window.size)))
		if physical.has_area():
			var ratio := viewport_size / Vector2(window.size)
			safe = Rect2((physical.position - Vector2(window.position)) * ratio, physical.size * ratio)
	var bounds := screen_to_page * safe
	var side_margin := maxf(40.0, bounds.size.x * 0.035)
	var width := bounds.size.x - side_margin * 2.0
	page_title.position = bounds.position + Vector2(side_margin, 24)
	page_title.size = Vector2(width, 90)
	var buttons_y := bounds.end.y - 112.0
	settings_panel.position = bounds.position + Vector2(side_margin, 132)
	settings_panel.size = Vector2(width, buttons_y - settings_panel.position.y - 64.0)
	footer_label.position = Vector2(bounds.position.x + side_margin, buttons_y - 48)
	footer_label.size = Vector2(width, 32)
	footer_buttons.position = Vector2(bounds.get_center().x - 335.0, buttons_y)
	footer_buttons.size = Vector2(670.0, 80.0)

func _sync_privacy() -> void:
	if not is_instance_valid(privacy_button):
		return
	var ads := get_node_or_null("/root/RewardedAds")
	if ads == null or not ads.privacy_supported():
		privacy_button.disabled = true
		privacy_status.text = _text("Disponibile nell'app mobile.", "Available in the mobile app.")
		return
	var required: bool = bool(ads.privacy_options_required())
	privacy_button.disabled = not required
	if not str(ads.privacy_message).is_empty():
		privacy_status.text = str(ads.privacy_message)
	elif required:
		privacy_status.text = _text(
			"Puoi modificare o revocare qui le preferenze pubblicitarie.",
			"You can change or withdraw your advertising preferences here."
		)
	else:
		privacy_status.text = _text(
			"Al momento non sono richieste opzioni privacy aggiuntive.",
			"No additional privacy options are currently required."
		)

func _on_push_registration_changed(registered: bool, message: String) -> void:
	if not is_instance_valid(push_status):
		return
	push_status.text = message
	push_status.add_theme_color_override("font_color", Color("78e08f") if registered else Style.TEXT)

func _process(_delta: float) -> void:
	if mic_test == null: return
	if not is_visible_in_tree() and mic_test.active: mic_test.stop()
	mic_meter.value = mic_test.level * 100.0
	test_button.text = _text("FERMA TEST", "STOP TEST") if mic_test.active else _text("TEST MICROFONO", "TEST MICROPHONE")
	mic_status.text = _text(mic_test.message_it, mic_test.message_en)

func _refresh_account_dot() -> void:
	if is_instance_valid(account_dot):
		account_dot.visible = get_node("/root/AccountProfile").needs_username()
	if is_instance_valid(account_name):
		var profile: Dictionary = get_node("/root/AccountProfile").profile
		var username = profile.get("username")
		account_name.text = "USERNAME: " + (str(username) if username != null and not str(username).strip_edges().is_empty() else _text("NON SCELTO", "NOT SET"))
		var public_id = profile.get("public_id")
		account_id.text = "ID BISCA: " + ("#" + str(public_id) if public_id != null and not str(public_id).is_empty() else _text("IN ATTESA", "PENDING"))
	if is_instance_valid(save_progress):
		save_progress.visible = not get_node("/root/AccountSession").password_ready

func _account_action(menu: Control, parent: Control, it: String, en: String, action: String, locked: bool) -> Button:
	var button: Button = menu._button(parent, "", func():
		var session := get_node("/root/AccountSession")
		var next := action
		if action == "save":
			next = "verify" if not session.pending_email.is_empty() else ("password" if session.email_verified else "link")
		var panel := preload("res://scenes/balatro/scripts/account_panel.gd").new()
		add_child(panel)
		panel.setup(menu, next)
	)
	_translated(button, it, en)
	button.custom_minimum_size = Vector2(600, 76)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 30)
	_set_button_radius(button, 38)
	button.disabled = locked
	if locked:
		_translated(button, "Gestisci l'account dal menu principale.", "Manage your account from the main menu.", "tooltip_text")
	return button

func _set_button_radius(button: Button, radius: int) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var base_style := button.get_theme_stylebox(state)
		if base_style is StyleBoxFlat:
			var style := (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
			style.set_corner_radius_all(radius)
			button.add_theme_stylebox_override(state, style)

func _label(text: String, font_size: int = 32) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Style.TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _row(parent: Control, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 76
	row.add_theme_constant_override("separation", 22)
	parent.add_child(row)
	var label := _label(title)
	label.custom_minimum_size.x = 380
	row.add_child(label)
	return row

func _add_slider(parent: Control, title: String, key: String) -> void:
	var row := _row(parent, title)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["slider", "grabber_area", "grabber_area_highlight"]:
		var track := StyleBoxFlat.new()
		track.bg_color = Style.SHADOW if state == "slider" else Style.HOVER
		track.set_corner_radius_all(5)
		track.content_margin_top = 4
		track.content_margin_bottom = 4
		slider.add_theme_stylebox_override(state, track)
	slider.add_theme_icon_override("grabber", preload("res://scenes/balatro/visuals/settings_knob.svg"))
	slider.add_theme_icon_override("grabber_highlight", preload("res://scenes/balatro/visuals/settings_knob_hover.svg"))
	row.add_child(slider)
	var number := _label("100")
	number.size_flags_horizontal = Control.SIZE_FILL
	number.custom_minimum_size.x = 65
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(number)
	sliders[key] = slider
	numbers[key] = number
	slider.value_changed.connect(func(value): settings.set_value(key, value))
	# One preview after adjustment, not on every step while dragging.
	slider.drag_ended.connect(func(_changed):
		preload("res://scenes/balatro/scripts/game_audio.gd").play(self, Audio.HOVER, -4.0)
	)

func _add_toggle(parent: Control, title: String, key: String) -> void:
	var row := _row(parent, title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var toggle := CheckButton.new()
	toggle.add_theme_icon_override("checked", preload("res://scenes/balatro/visuals/settings_toggle_on.svg"))
	toggle.add_theme_icon_override("unchecked", preload("res://scenes/balatro/visuals/settings_toggle_off.svg"))
	toggle.custom_minimum_size = Vector2(120, 76)
	toggle.add_theme_color_override("font_color", Style.TEXT)
	row.add_child(toggle)
	Audio.attach(toggle)
	toggles[key] = toggle
	toggle.toggled.connect(func(enabled): settings.set_value(key, enabled))

func _sync() -> void:
	_refresh_account_dot()
	for key in sliders:
		sliders[key].set_value_no_signal(settings.values[key])
		numbers[key].text = str(int(settings.values[key]))
	for key in toggles:
		toggles[key].set_pressed_no_signal(settings.values[key])
	if OS.get_name() == "iOS" and not get_node("/root/PushNotifications").IOS_PUSH_ENABLED:
		toggles.push_notifications.set_pressed_no_signal(false)

	for entry in translations:
		entry[0].set(entry[1], _text(entry[2], entry[3]))
	language.select(1 if settings.values.language == "en" else 0)
	_sync_privacy()
