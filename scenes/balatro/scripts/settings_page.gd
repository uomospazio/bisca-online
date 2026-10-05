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
var tabs: TabContainer
var language: OptionButton
var reset_dialog: ConfirmationDialog
var mic_test: Node
var mic_meter: ProgressBar
var mic_status: Label
var test_button: Button

func _text(it: String, en: String) -> String:
	return en if settings.values.language == "en" else it

func _translated(node: Node, it: String, en: String, property: String = "text") -> void:
	translations.append([node, property, it, en])
	node.set(property, _text(it, en))

func _tab(it: String, en: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = it
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	scroll.set_meta("titles", [it, en])
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 24)
	scroll.add_child(rows)
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
	var title := _label("", 66)
	_translated(title, "SETTINGS", "SETTINGS")
	add_child(title)
	title.position = Vector2(240, 125)
	title.size = Vector2(1440, 95)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Style.HOVER)
	title.add_theme_constant_override("outline_size", 12)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.position = Vector2(240, 280)
	panel.size = Vector2(1440, 520)
	var skin := Style.button_style(Style.PANEL, Style.HOVER, 4)
	skin.content_margin_left = 36
	skin.content_margin_right = 36
	skin.content_margin_top = 28
	skin.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", skin)
	tabs = TabContainer.new()
	tabs.custom_minimum_size = Vector2(1368, 464)
	tabs.add_theme_font_override("font", FONT)
	tabs.add_theme_font_size_override("font_size", 25)
	panel.add_child(tabs)
	var audio := _tab("AUDIO", "AUDIO")
	_setting(audio, "VOLUME GENERALE", "MASTER VOLUME", "main", true)
	_setting(audio, "EFFETTI", "SOUND EFFECTS", "effects", true)
	var microphone := _tab("MICROFONO", "MICROPHONE")
	_setting(microphone, "MICROFONO ABILITATO", "MICROPHONE ENABLED", "microphone_enabled")
	_setting(microphone, "PREMI PER PARLARE", "PUSH TO TALK", "push_to_talk")
	var hint := _label("", 20)
	_translated(hint, "Tieni premuto V o il pulsante microfono al tavolo per parlare.", "Hold V or the microphone button at the table to talk.")
	microphone.add_child(hint)
	mic_test = preload("res://scenes/balatro/scripts/settings_mic_test.gd").new()
	add_child(mic_test)
	test_button = menu._button(microphone, "", func():
		if mic_test.active: mic_test.stop()
		else: mic_test.start()
	)
	test_button.custom_minimum_size = Vector2(320, 64)
	mic_meter = ProgressBar.new()
	mic_meter.custom_minimum_size.y = 28
	mic_meter.show_percentage = false
	microphone.add_child(mic_meter)
	mic_status = _label("", 20)
	microphone.add_child(mic_status)
	var graphics := _tab("GRAFICA", "GRAPHICS")
	_setting(graphics, "MOVIMENTO CAMERA", "CAMERA MOVEMENT", "camera")
	_setting(graphics, "ANIMAZIONI TESTO", "TEXT ANIMATIONS", "text_animations")
	_setting(graphics, "SCHERMO INTERO", "FULLSCREEN", "fullscreen")
	if OS.get_name() in ["Android", "iOS", "Web"]:
		toggles.fullscreen.disabled = true
		_translated(toggles.fullscreen, "Disponibile nella versione PC", "Available on desktop", "tooltip_text")
	var general := _tab("GENERALE", "GENERAL")
	_setting(general, "MOSTRA OGGETTI LANCIATI", "SHOW THROWN OBJECTS", "show_thrown_objects")
	_setting(general, "NOTIFICHE PUSH", "PUSH NOTIFICATIONS", "push_notifications")
	if OS.get_name() not in ["Android", "iOS"]:
		toggles.push_notifications.disabled = true
		_translated(toggles.push_notifications, "Disponibili nell'app mobile", "Available in the mobile app", "tooltip_text")
	var note := _label("", 20)
	_translated(note, "Disattivando gli oggetti vengono silenziati anche i loro suoni.", "Hiding thrown objects also mutes their sounds.")
	general.add_child(note)
	var row := _row(general, "")
	_translated(row.get_child(0), "LINGUA", "LANGUAGE")
	language = OptionButton.new()
	language.add_item("Italiano")
	language.add_item("English")
	language.add_theme_font_override("font", FONT)
	language.add_theme_font_size_override("font_size", 26)
	row.add_child(language)
	language.item_selected.connect(func(index): settings.set_value("language", "en" if index == 1 else "it"))
	var account := _tab("ACCOUNT", "ACCOUNT")
	var account_button: Button = menu._button(account, "", func():
		var account_panel := preload("res://scenes/balatro/scripts/account_panel.gd").new()
		add_child(account_panel)
		account_panel.setup(menu)
	)
	_translated(account_button, "GESTISCI ACCOUNT", "MANAGE ACCOUNT")
	account_button.custom_minimum_size = Vector2(360, 64)
	account_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_set_button_radius(account_button, 32)
	account_dot = menu._notification_dot(account_button)
	get_node("/root/AccountProfile").changed.connect(_refresh_account_dot)
	get_node("/root/AccountSession").changed.connect(_refresh_account_dot)
	_refresh_account_dot()
	account_button.disabled = back_action.is_valid()
	_translated(account_button, "Gestisci l'account dal menu principale.", "Manage your account from the main menu.", "tooltip_text")
	var footer := _label("", 18)
	_translated(footer, "LE MODIFICHE VENGONO SALVATE AUTOMATICAMENTE", "CHANGES ARE SAVED AUTOMATICALLY")
	add_child(footer)
	footer.position = Vector2(240, 810)
	footer.size.x = 1440
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reset_dialog = ConfirmationDialog.new()
	add_child(reset_dialog)
	_translated(reset_dialog, "RIPRISTINA IMPOSTAZIONI", "RESET SETTINGS", "title")
	_translated(reset_dialog, "Ripristinare tutte le impostazioni ai valori predefiniti?", "Restore all settings to their defaults?", "dialog_text")
	_translated(reset_dialog.get_ok_button(), "RIPRISTINA", "RESET")
	_translated(reset_dialog.get_cancel_button(), "ANNULLA", "CANCEL")
	reset_dialog.confirmed.connect(settings.reset_defaults)
	var buttons := HBoxContainer.new()
	add_child(buttons)
	buttons.position = Vector2(530, 870)
	buttons.size.x = 860
	buttons.add_theme_constant_override("separation", 30)
	var back: Button = menu._button(buttons, "", back_action if back_action.is_valid() else menu.show_home)
	_translated(back, "INDIETRO", "BACK")
	var reset: Button = menu._button(buttons, "", func(): reset_dialog.popup_centered(Vector2i(640, 200)))
	_translated(reset, "RIPRISTINA", "RESET")
	for button in [back, reset]:
		button.custom_minimum_size = Vector2(320, 80)
		_set_button_radius(button, 40)
	tabs.tab_changed.connect(func(_index): mic_test.stop())
	settings.changed.connect(_sync)
	_sync()

func _process(_delta: float) -> void:
	if mic_test == null: return
	if not is_visible_in_tree() and mic_test.active: mic_test.stop()
	mic_meter.value = mic_test.level * 100.0
	test_button.text = _text("FERMA TEST", "STOP TEST") if mic_test.active else _text("TEST MICROFONO", "TEST MICROPHONE")
	mic_status.text = _text(mic_test.message_it, mic_test.message_en)

func _refresh_account_dot() -> void:
	if is_instance_valid(account_dot):
		account_dot.visible = get_node("/root/AccountProfile").needs_username()

func _set_button_radius(button: Button, radius: int) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var base_style := button.get_theme_stylebox(state)
		if base_style is StyleBoxFlat:
			var style := (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
			style.set_corner_radius_all(radius)
			button.add_theme_stylebox_override(state, style)

func _label(text: String, font_size: int = 26) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Style.TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _row(parent: Control, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 48
	row.add_theme_constant_override("separation", 22)
	parent.add_child(row)
	var label := _label(title)
	label.custom_minimum_size.x = 335
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
	toggle.custom_minimum_size = Vector2(110, 48)
	toggle.add_theme_color_override("font_color", Style.TEXT)
	row.add_child(toggle)
	Audio.attach(toggle)
	toggles[key] = toggle
	toggle.toggled.connect(func(enabled): settings.set_value(key, enabled))

func _sync() -> void:
	for key in sliders:
		sliders[key].set_value_no_signal(settings.values[key])
		numbers[key].text = str(int(settings.values[key]))
	for key in toggles:
		toggles[key].set_pressed_no_signal(settings.values[key])

	for entry in translations:
		entry[0].set(entry[1], _text(entry[2], entry[3]))
	language.select(1 if settings.values.language == "en" else 0)
	for index in tabs.get_tab_count():
		var titles: Array = tabs.get_tab_control(index).get_meta("titles")
		tabs.set_tab_title(index, _text(titles[0], titles[1]))
