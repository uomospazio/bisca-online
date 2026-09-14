extends Control

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const Audio = preload("res://scenes/balatro/scripts/button_audio.gd")
var settings: Node
var sliders: Dictionary = {}
var numbers: Dictionary = {}
var toggles: Dictionary = {}

func setup(menu: Control, back_action: Callable = Callable()) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings = get_node("/root/GameSettings")
	var title := _label("SETTINGS", 66)
	add_child(title)
	title.position = Vector2(400, 125)
	title.size = Vector2(1120, 95)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Style.HOVER)
	title.add_theme_constant_override("outline_size", 12)
	var panel := PanelContainer.new()
	add_child(panel)
	panel.position = Vector2(530, 280)
	panel.size = Vector2(860, 520)
	var skin := Style.button_style(Style.NORMAL, Style.HOVER, 4)
	skin.content_margin_left = 36
	skin.content_margin_right = 36
	skin.content_margin_top = 28
	skin.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", skin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 24)
	panel.add_child(rows)
	_add_slider(rows, "MAIN", "main")
	_add_slider(rows, "EFFECTS", "effects")
	var separator := HSeparator.new()
	rows.add_child(separator)
	_add_toggle(rows, "MOVIMENTO CAMERA", "camera")
	_add_toggle(rows, "TOOLTIP CARTE", "tooltips")
	_add_toggle(rows, "SCHERMO INTERO", "fullscreen")
	if OS.get_name() in ["Android", "iOS", "Web"]:
		toggles.fullscreen.disabled = true
		toggles.fullscreen.tooltip_text = "Disponibile nella versione PC"
	var footer := _label("LE MODIFICHE VENGONO SALVATE AUTOMATICAMENTE", 18)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(footer)
	var buttons := HBoxContainer.new()
	add_child(buttons)
	buttons.position = Vector2(530, 850)
	buttons.size.x = 860
	buttons.add_theme_constant_override("separation", 30)
	var back: Button = menu._button(buttons, "INDIETRO", back_action if back_action.is_valid() else menu.show_home)
	back.custom_minimum_size = Vector2(320, 80)
	var reset: Button = menu._button(buttons, "RIPRISTINA", settings.reset_defaults)
	reset.custom_minimum_size = Vector2(320, 80)
	settings.changed.connect(_sync)
	_sync()

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
		track.bg_color = Style.SHADOW if state == "slider" else Style.TEXT
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
