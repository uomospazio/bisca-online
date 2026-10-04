extends PanelContainer

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
var content: VBoxContainer

const Stepper = preload("res://scenes/balatro/scripts/option_stepper.gd")
var lives: Stepper
var rounds: Stepper
var bot_count: Stepper
var fill_bots: CheckButton
var compact_rows := false
var turn_timer: Stepper
const TURN_TIMES := [15, 30, 60, 0]

func setup(menu: Control, multiplayer_game: bool) -> void:
	compact_rows = not multiplayer_game
	var panel_style := Style.button_style(Style.PANEL, Style.HOVER, 4)
	panel_style.set_corner_radius_all(20)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	if compact_rows:
		panel_style.bg_color = Color.TRANSPARENT
		panel_style.border_color = Color.TRANSPARENT
		panel_style.shadow_color = Color.TRANSPARENT
	add_theme_stylebox_override("panel", panel_style)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	add_child(content)
	var heading := preload("res://scenes/balatro/scripts/idle_subtitle.gd").new()
	heading.text = "IMPOSTAZIONI PARTITA"
	heading.add_theme_font_override("font", menu.KIDS_FONT)
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", Style.TEXT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(heading)
	heading.visible = multiplayer_game
	heading.set_animated(false)
	heading.add_theme_color_override("font_outline_color", preload("res://scenes/balatro/scripts/player_badge.gd").NAME_OUTLINE_COLOR)
	heading.add_theme_constant_override("outline_size", 10)
	heading.custom_minimum_size.y = 48 if multiplayer_game else 0
	lives = _stepper(menu, "VITE INIZIALI", 1, 10, 3)
	rounds = _stepper(menu, "CARTE DI PARTENZA", 1, 5, 5)
	if multiplayer_game:
		fill_bots = CheckButton.new()
		fill_bots.tooltip_text = "Riempi i posti liberi con i bot"
		fill_bots.add_theme_font_override("font", menu.KIDS_FONT)
		fill_bots.add_theme_color_override("font_color", Style.TEXT)
		fill_bots.add_theme_font_size_override("font_size", 32)
		fill_bots.add_theme_icon_override("checked", preload("res://scenes/balatro/visuals/settings_toggle_on.svg"))
		fill_bots.add_theme_icon_override("unchecked", preload("res://scenes/balatro/visuals/settings_toggle_off.svg"))
		fill_bots.custom_minimum_size.y = 64
		preload("res://scenes/balatro/scripts/rounded_square_button.gd").ButtonAudio.attach(fill_bots)
	bot_count = _stepper(menu, "BOT", 1, 7, 2 if multiplayer_game else 7)
	if multiplayer_game:
		var bot_row := bot_count.get_parent()
		bot_row.get_child(0).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		bot_row.add_child(fill_bots)
		bot_row.move_child(fill_bots, 1)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bot_row.add_child(spacer)
		bot_row.move_child(spacer, 2)
		turn_timer = _stepper(menu, "TEMPO PER TURNO", 0, 3, 1)
		turn_timer.value_labels = ["15 s", "30 s", "60 s", "∞"]
		turn_timer.tooltip_text = "15, 30, 60 secondi oppure senza limite (∞)"
		turn_timer._refresh()
		fill_bots.toggled.connect(func(_on): update_bot_limit(int(bot_count.max_value), true))
		update_bot_limit(7, true)

func update_bot_limit(free_seats: int, can_edit: bool) -> void:
	bot_count.min_value = 0 if free_seats == 0 else 1
	bot_count.max_value = maxi(0, free_seats)
	bot_count.value = mini(bot_count.value, free_seats)
	bot_count.editable = can_edit and free_seats > 0 and fill_bots.button_pressed
	fill_bots.disabled = not can_edit or free_seats == 0

func reset_multiplayer() -> void:
	if compact_rows: return
	lives.value = 3
	rounds.value = 5
	fill_bots.button_pressed = false
	update_bot_limit(7, true)
	bot_count.value = 2
	turn_timer.value = 1

func reset_singleplayer() -> void:
	if not compact_rows: return
	lives.value = 3
	rounds.value = 5
	bot_count.value = 7
	var english: bool = get_node("/root/GameSettings").values.language == "en"
	lives.get_parent().get_child(0).tooltip_text = "Starting lives" if english else "Vite iniziali"
	rounds.get_parent().get_child(0).text = "STARTING CARDS" if english else "CARTE DI PARTENZA"

func values() -> Dictionary:
	var result := {"lives": int(lives.value), "starting_cards": int(rounds.value),
		"bots": fill_bots == null or fill_bots.button_pressed, "bot_count": int(bot_count.value)}
	if turn_timer != null: result["turn_seconds"] = TURN_TIMES[int(turn_timer.value)]
	return result

func _stepper(menu: Control, caption: String, minimum: int, maximum: int, initial: int) -> Stepper:
	var row: BoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	content.add_child(row)
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", menu.KIDS_FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Style.TEXT)
	if compact_rows and caption == "VITE INIZIALI":
		var heart := TextureRect.new()
		heart.texture = preload("res://scenes/balatro/trick_asset/mazzo_2/briscola/heart.svg")
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		heart.custom_minimum_size = Vector2(64, 64)
		heart.tooltip_text = "Vite iniziali"
		row.add_child(heart)
		var space := Control.new()
		space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(space)
		label.free()
	else:
		row.add_child(label)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var selector := Stepper.new()
	selector.min_value = minimum
	selector.max_value = maximum
	selector.step = 1
	selector.value = initial
	selector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(selector)
	selector.setup(menu.KIDS_FONT)
	if compact_rows:
		selector.caption.add_theme_color_override("font_color", Color("f3effe"))
		if caption == "VITE INIZIALI":
			for button in [selector.previous, selector.next_button]:
				button.icon = null
				button.add_theme_font_override("font", menu.KIDS_FONT)
				button.add_theme_font_size_override("font_size", 30)
				button.add_theme_color_override("font_color", Color("f3effe"))
			selector.previous.text = "-"
			selector.next_button.text = "+"
	return selector
