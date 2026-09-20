extends PanelContainer

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
var content: VBoxContainer

var lives: HSlider
var rounds: HSlider
var bot_count: HSlider
var fill_bots: CheckButton

func setup(menu: Control, multiplayer_game: bool) -> void:
	var panel_style := Style.button_style(Style.NORMAL, Style.HOVER, 4)
	panel_style.set_corner_radius_all(20)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", panel_style)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	add_child(content)
	var heading := Label.new()
	heading.text = "IMPOSTAZIONI PARTITA"
	heading.add_theme_font_override("font", menu.KIDS_FONT)
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Style.TEXT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	lives = _slider(menu, "VITE INIZIALI", 1, 10, 3)
	rounds = _slider(menu, "CARTE DI PARTENZA", 1, 5, 5)
	if multiplayer_game:
		fill_bots = CheckButton.new()
		fill_bots.text = "RIEMPI CON BOT"
		fill_bots.add_theme_font_override("font", menu.KIDS_FONT)
		fill_bots.add_theme_color_override("font_color", menu.BUTTON_TEXT)
		fill_bots.add_theme_font_size_override("font_size", 24)
		fill_bots.add_theme_icon_override("checked", preload("res://scenes/balatro/visuals/settings_toggle_on.svg"))
		fill_bots.add_theme_icon_override("unchecked", preload("res://scenes/balatro/visuals/settings_toggle_off.svg"))
		content.add_child(fill_bots)
		preload("res://scenes/balatro/scripts/rounded_square_button.gd").ButtonAudio.attach(fill_bots)
	bot_count = _slider(menu, "BOT", 1, 7, 2)
	if multiplayer_game:
		bot_count.get_parent().hide()
		fill_bots.toggled.connect(func(on): bot_count.get_parent().visible = on)

func values() -> Dictionary:
	return {"lives": int(lives.value), "starting_cards": int(rounds.value),
		"bots": fill_bots == null or fill_bots.button_pressed, "bot_count": int(bot_count.value)}

func _slider(menu: Control, caption: String, minimum: int, maximum: int, initial: int) -> HSlider:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 56
	row.add_theme_constant_override("separation", 20)
	content.add_child(row)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 285
	label.add_theme_font_override("font", menu.KIDS_FONT)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", menu.BUTTON_TEXT)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 1
	slider.value = initial
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
	var value := Label.new()
	value.text = str(initial)
	value.custom_minimum_size.x = 45
	value.add_theme_font_override("font", menu.KIDS_FONT)
	value.add_theme_color_override("font_color", menu.BUTTON_TEXT)
	row.add_child(value)
	slider.value_changed.connect(func(number): value.text = str(int(number)))
	return slider
