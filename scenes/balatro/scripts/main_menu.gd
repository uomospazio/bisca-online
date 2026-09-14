extends Control

const KIDS_FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const COUNTER_FONT = KIDS_FONT
const MixedLabel = preload("res://scenes/balatro/scripts/mixed_label.gd")
const ButtonShadow = preload("res://scenes/balatro/scripts/button_shadow.gd")
const RoundedSquareButton = preload("res://scenes/balatro/scripts/rounded_square_button.gd")

# Layout del menu sulla viewport di progetto 1920x1080.
# Modifica questi valori per spostare o ridimensionare gli elementi senza
# dover intervenire sulla gerarchia dei contenitori.
const TITLE_POSITION := Vector2(0, 120)
const TITLE_SIZE := Vector2(1920, 280)
const HOME_BUTTONS_POSITION := Vector2(730, 470)
const HOME_BUTTONS_SIZE := Vector2(460, 456)
const SETUP_ELEMENTS_POSITION := Vector2(640, 530)
const SETUP_ELEMENTS_SIZE := Vector2(640, 540)
const MENU_BUTTON_HEIGHT := 96.0
const LexispellStyle = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const BUTTON_PURPLE := LexispellStyle.NORMAL
const BUTTON_PURPLE_PRESSED := LexispellStyle.NORMAL
const BUTTON_CYAN := LexispellStyle.HOVER
const BUTTON_DISABLED := LexispellStyle.DISABLED
const BUTTON_TEXT := LexispellStyle.TEXT
const BUTTON_RED := Color(0.89, 0.3204, 0.3204)

signal start_requested(player_name: String, count: int)

var name_input: LineEdit
var home_page: VBoxContainer
var setup_page: VBoxContainer
var bot_slider: HSlider
var single_name_input: LineEdit
var title: Control
var friends_subtitle: Label
var title_letters: Array[Control] = []
var network_page: Control
var menu_content: Control
var active_page: Control
var settings_page: Control
const PageTransition = preload("res://scenes/balatro/scripts/page_transition.gd")

func _switch_page(next: Control, backwards := false) -> void:
	var previous := active_page if is_instance_valid(active_page) else home_page
	active_page = next
	PageTransition.slide(self, previous, next, backwards)

# Parallax del menu, uguale al movimento MouseOffset usato da Lexispell.
const MENU_OFFSET_STRENGTH := 10.0
const MENU_OFFSET_SMOOTHING := 2.5

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The shared animated background stays visible behind every menu page.
	menu_content = Control.new()
	add_child(menu_content)
	menu_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_title(menu_content)
	friends_subtitle = Label.new()
	menu_content.add_child(friends_subtitle)
	friends_subtitle.text = "WITH YOUR FRIENDS"
	friends_subtitle.position = Vector2(0, 175)
	friends_subtitle.size = Vector2(1920, 44)
	friends_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friends_subtitle.add_theme_font_override("font", KIDS_FONT)
	friends_subtitle.add_theme_font_size_override("font_size", 32)
	friends_subtitle.add_theme_color_override("font_color", BUTTON_TEXT)
	friends_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	friends_subtitle.hide()
	home_page = VBoxContainer.new()
	home_page.add_theme_constant_override("separation", 24)
	menu_content.add_child(home_page)
	home_page.position = HOME_BUTTONS_POSITION
	home_page.size = HOME_BUTTONS_SIZE
	_button(home_page, "SINGLEPLAYER", show_setup)
	_button(home_page, "MULTIPLAYER", _show_network)
	_button(home_page, "SETTINGS", _show_settings)
	var quit_button := _button(home_page, "QUIT", func(): get_tree().quit())
	quit_button.add_theme_stylebox_override("normal", _menu_button_style(BUTTON_RED))
	quit_button.add_theme_stylebox_override("hover", _menu_button_style(BUTTON_CYAN, BUTTON_TEXT, 6))
	quit_button.add_theme_stylebox_override("pressed", _menu_button_style(BUTTON_PURPLE_PRESSED, BUTTON_TEXT, 2))
	name_input = LineEdit.new()
	name_input.virtual_keyboard_enabled = true
	name_input.virtual_keyboard_show_on_focus = true
	name_input.placeholder_text = "COME TI CHIAMI?"
	name_input.max_length = 16
	name_input.custom_minimum_size.x = 520
	name_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_input.custom_minimum_size.y = 58
	name_input.add_theme_font_size_override("font_size", 26)
	_style_input(name_input, 26)
	# Shared name field is displayed in the multiplayer page when created.
	add_child(name_input)
	name_input.hide()
	setup_page = VBoxContainer.new()
	setup_page.add_theme_constant_override("separation", 18)
	menu_content.add_child(setup_page)
	setup_page.position = SETUP_ELEMENTS_POSITION
	setup_page.size = SETUP_ELEMENTS_SIZE
	single_name_input = LineEdit.new()
	single_name_input.virtual_keyboard_enabled = true
	single_name_input.virtual_keyboard_show_on_focus = true
	single_name_input.placeholder_text = "COME TI CHIAMI?"
	single_name_input.max_length = 16
	single_name_input.custom_minimum_size.x = 520
	single_name_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	single_name_input.custom_minimum_size.y = 72
	_style_input(single_name_input, 28)
	setup_page.add_child(single_name_input)
	single_name_input.text_changed.connect(func(value):
		name_input.text = value
	)
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 80
	row.add_theme_constant_override("separation", 24)
	setup_page.add_child(row)
	var caption := Label.new()
	caption.text = "BOT"
	caption.add_theme_color_override("font_color", BUTTON_TEXT)
	row.add_child(caption)
	bot_slider = HSlider.new()
	bot_slider.min_value = 1
	bot_slider.max_value = 7
	bot_slider.step = 1
	bot_slider.value = 2
	bot_slider.tick_count = 7
	bot_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["slider", "grabber_area", "grabber_area_highlight"]:
		var track := StyleBoxFlat.new()
		track.bg_color = BUTTON_PURPLE if state == "slider" else BUTTON_TEXT
		track.set_corner_radius_all(5)
		track.content_margin_top = 4
		track.content_margin_bottom = 4
		bot_slider.add_theme_stylebox_override(state, track)
	bot_slider.add_theme_icon_override("grabber", preload("res://scenes/balatro/visuals/settings_knob.svg"))
	bot_slider.add_theme_icon_override("grabber_highlight", preload("res://scenes/balatro/visuals/settings_knob_hover.svg"))
	row.add_child(bot_slider)
	var value_label := Label.new()
	value_label.text = "2"
	value_label.custom_minimum_size.x = 42
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", BUTTON_TEXT)
	row.add_child(value_label)
	bot_slider.value_changed.connect(func(value): value_label.text = str(int(value)))
	bot_slider.drag_ended.connect(func(_changed):
		preload("res://scenes/balatro/scripts/game_audio.gd").play(self, RoundedSquareButton.ButtonAudio.HOVER, -4.0)
	)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	setup_page.add_child(buttons)
	var back := _button(buttons, "Indietro", show_home)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var play := _button(buttons, "Gioca", _start)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_page.hide()
	_start_title_wave()

func _process(delta: float) -> void:
	if not is_instance_valid(menu_content) or not menu_content.is_inside_tree():
		return
	var center := get_viewport_rect().size / 2.0
	if center.x <= 0.0 or center.y <= 0.0:
		return
	var mouse := get_global_mouse_position()
	var offset := mouse / center - Vector2.ONE
	var target_position := -offset * MENU_OFFSET_STRENGTH
	if not get_node("/root/GameSettings").values.camera or DisplayServer.is_touchscreen_available():
		target_position = Vector2.ZERO
	menu_content.position = menu_content.position.lerp(target_position, MENU_OFFSET_SMOOTHING * delta)

func _show_network() -> void:
	_show_menu_title(true)
	if not is_instance_valid(network_page):
		network_page = preload("res://scenes/balatro/scripts/network_lobby.gd").new()
		add_child(network_page)
		network_page.setup(self)
	network_page.open()
	_switch_page(network_page)

func _show_settings() -> void:
	title.hide()
	friends_subtitle.hide()
	if not is_instance_valid(settings_page):
		settings_page = preload("res://scenes/balatro/scripts/settings_page.gd").new()
		add_child(settings_page)
		settings_page.setup(self)
	_switch_page(settings_page)

func _show_menu_title(with_friends: bool = false) -> void:
	title.show()
	friends_subtitle.add_theme_font_size_override("font_size", 32)
	friends_subtitle.text = "WITH YOUR FRIENDS"
	friends_subtitle.position = Vector2(0, 400)
	friends_subtitle.add_theme_font_size_override("font_size", 56)
	title.scale = Vector2.ONE
	title.position = TITLE_POSITION
	friends_subtitle.visible = with_friends

func _label(parent: Node, text: String, font_size: int) -> MixedLabel:
	var label := MixedLabel.new()
	label.set_mixed_text(text)
	label.add_theme_font_override("normal_font", KIDS_FONT)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("font_color", Color("474660"))
	parent.add_child(label)
	return label

func _build_title(parent: Control) -> void:
	title = Control.new()
	title.position = TITLE_POSITION
	title.size = TITLE_SIZE
	parent.add_child(title)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", -4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)
	var title_font := KIDS_FONT
	for character in "BISCA":
		var letter := Control.new()
		var width := title_font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, 196).x
		letter.custom_minimum_size = Vector2(width + 34, 264)
		letter.pivot_offset = letter.custom_minimum_size / 2.0
		row.add_child(letter)
		var outer := Label.new()
		outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		outer.text = character
		outer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		outer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		outer.add_theme_font_override("font", title_font)
		outer.add_theme_font_size_override("font_size", 296)
		outer.add_theme_color_override("font_color", Color("474660"))
		outer.add_theme_color_override("font_outline_color", Color("fde4b9"))
		outer.add_theme_constant_override("outline_size", 20)
		letter.add_child(outer)
		var inner := Label.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.text = character
		inner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		inner.add_theme_font_override("font", title_font)
		inner.add_theme_font_size_override("font_size", 296)
		inner.add_theme_color_override("font_color", Color("474660"))
		inner.add_theme_color_override("font_outline_color", Color("fde4b9"))
		inner.add_theme_constant_override("outline_size", 30)
		letter.add_child(inner)
		title_letters.append(letter)

func _start_title_wave() -> void:
	while is_inside_tree():
		await get_tree().create_timer(3.0, false).timeout
		if not is_instance_valid(title) or not title.visible:
			continue
		var wave := create_tween()
		for letter in title_letters:
			letter.pivot_offset = letter.size / 2.0
			wave.tween_property(letter, "scale", Vector2(1.08, 1.08), 0.10)
			wave.parallel().tween_property(letter, "rotation", deg_to_rad(-4.0), 0.10)
			wave.tween_property(letter, "scale", Vector2.ONE, 0.16)
			wave.parallel().tween_property(letter, "rotation", 0.0, 0.16)

func _style_input(input: LineEdit, font_size: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fde4b9")
	style.border_color = Color("263d30")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	input.add_theme_stylebox_override("normal", style)
	input.add_theme_font_override("font", KIDS_FONT)
	input.add_theme_font_size_override("font_size", font_size)
	input.add_theme_color_override("font_color", Color("474660"))
	input.add_theme_color_override("font_placeholder_color", Color("777b72"))
	input.add_theme_color_override("caret_color", Color("474660"))

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := RoundedSquareButton.new()
	button.text = text.to_upper()
	button.custom_minimum_size.y = MENU_BUTTON_HEIGHT
	button.add_theme_font_override("font", KIDS_FONT)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_stylebox_override("normal", _menu_button_style(BUTTON_PURPLE))
	button.add_theme_stylebox_override("hover", _menu_button_style(BUTTON_CYAN, BUTTON_TEXT, 6))
	button.add_theme_stylebox_override("pressed", _menu_button_style(BUTTON_PURPLE_PRESSED, BUTTON_TEXT, 2))
	button.add_theme_stylebox_override("disabled", _menu_button_style(BUTTON_DISABLED))
	button.add_theme_color_override("font_color", BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", BUTTON_TEXT)
	button.add_theme_color_override("font_pressed_color", BUTTON_TEXT)
	button.add_theme_color_override("font_disabled_color", LexispellStyle.DISABLED_TEXT)
	parent.add_child(button)
	button.pressed.connect(callback)
	return button

func _menu_button_style(color: Color, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	return LexispellStyle.button_style(color, border_color, border_width)

func _has_special(value: String) -> bool:
	for character in "+-/éÉ?'−·…":
		if value.contains(character):
			return true
	return false

func chosen_name() -> String:
	# Do not rewrite a focused LineEdit on every mobile input event: it
	# reopens the native keyboard and resets composition/caret positioning.
	var value := name_input.text.strip_edges().to_upper()
	return "Giocatore" if value.is_empty() else value

func show_setup() -> void:
	_show_menu_title()
	friends_subtitle.text = "SOLITARIA"
	friends_subtitle.add_theme_font_size_override("font_size", 56)
	friends_subtitle.position = Vector2(0, 400)
	friends_subtitle.show()
	single_name_input.text = name_input.text
	_switch_page(setup_page)

func show_home() -> void:
	_show_menu_title()
	_switch_page(home_page, true)

func _start() -> void:
	start_requested.emit(chosen_name(), int(bot_slider.value) + 1)
