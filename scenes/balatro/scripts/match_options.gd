extends PanelContainer

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
var content: VBoxContainer

const Stepper = preload("res://scenes/balatro/scripts/option_stepper.gd")
var lives: Stepper
var rounds: Stepper
var bot_count: Stepper
var fill_bots: CheckButton

func setup(menu: Control, multiplayer_game: bool) -> void:
	var panel_style := Style.button_style(Style.TEXT, Style.HOVER, 4)
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
	heading.add_theme_color_override("font_color", Style.NORMAL)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	lives = _stepper(menu, "VITE INIZIALI", 1, 10, 3)
	rounds = _stepper(menu, "CARTE DI PARTENZA", 1, 5, 5)
	if multiplayer_game:
		fill_bots = CheckButton.new()
		fill_bots.text = "RIEMPI CON BOT"
		fill_bots.add_theme_font_override("font", menu.KIDS_FONT)
		fill_bots.add_theme_color_override("font_color", Style.NORMAL)
		fill_bots.add_theme_font_size_override("font_size", 24)
		fill_bots.add_theme_icon_override("checked", preload("res://scenes/balatro/visuals/settings_toggle_on.svg"))
		fill_bots.add_theme_icon_override("unchecked", preload("res://scenes/balatro/visuals/settings_toggle_off.svg"))
		content.add_child(fill_bots)
		preload("res://scenes/balatro/scripts/rounded_square_button.gd").ButtonAudio.attach(fill_bots)
	bot_count = _stepper(menu, "BOT", 1, 7, 2)
	if multiplayer_game:
		bot_count.get_parent().hide()
		fill_bots.toggled.connect(func(on): bot_count.get_parent().visible = on)

func values() -> Dictionary:
	return {"lives": int(lives.value), "starting_cards": int(rounds.value),
		"bots": fill_bots == null or fill_bots.button_pressed, "bot_count": int(bot_count.value)}

func _stepper(menu: Control, caption: String, minimum: int, maximum: int, initial: int) -> Stepper:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", menu.KIDS_FONT)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Style.NORMAL)
	row.add_child(label)
	var selector := Stepper.new()
	selector.min_value = minimum
	selector.max_value = maximum
	selector.step = 1
	selector.value = initial
	selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(selector)
	selector.setup(menu.KIDS_FONT)
	return selector
