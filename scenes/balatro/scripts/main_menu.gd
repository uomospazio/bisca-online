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
var home_page: Control
var profile_picker: Node
var profile_button: TextureButton
var profile_avatar := ""
var profile_texture: Texture2D
var setup_page: VBoxContainer
var match_options: PanelContainer
var bot_slider: HSlider
var single_name_input: LineEdit
var title: Control
var friends_subtitle: Label
var title_letters: Array[Control] = []
var network_page: Control
var menu_content: Control
var active_page: Control
var settings_page: Control
var deck_selector: Control
const PageTransition = preload("res://scenes/balatro/scripts/page_transition.gd")

func _switch_page(next: Control, backwards := false) -> void:
	var previous := active_page if is_instance_valid(active_page) else home_page
	active_page = next
	if is_instance_valid(deck_selector):
		deck_selector.visible = next == home_page
		deck_selector.reset_preview()
	PageTransition.slide(self, previous, next, backwards)

# Parallax del menu, uguale al movimento MouseOffset usato da Lexispell.
const MENU_OFFSET_STRENGTH := 10.0
const MENU_OFFSET_SMOOTHING := 2.5

func _lock_landscape_web() -> void:
	if not OS.has_feature("web"):
		return

	JavaScriptBridge.eval("""
		(async () => {
			try {
				

				if (screen.orientation && screen.orientation.lock) {
					await screen.orientation.lock("landscape");
				}
			} catch (e) {
				console.log("Landscape lock non disponibile:", e);
			}
		})();
	""", true)

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
	home_page = Control.new()
	menu_content.add_child(home_page)
	home_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var play_choices := HBoxContainer.new()
	home_page.add_child(play_choices)
	play_choices.position = Vector2(560, 820)
	play_choices.size = Vector2(800, 96)
	play_choices.add_theme_constant_override("separation", 48)
	_button(play_choices, "SINGLEPLAYER", show_setup).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(play_choices, "MULTIPLAYER", _show_network).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var settings_button := _button(home_page, "SETTINGS", _show_settings)
	settings_button.position = Vector2(48, 156)
	settings_button.size = Vector2(240, 96)
	var info_button := _button(home_page, "INFO", _show_home_info)
	info_button.position = Vector2(48, 40)
	info_button.size = Vector2(240, 96)
	profile_picker = preload("res://scenes/balatro/scripts/profile_picker.gd").new()
	add_child(profile_picker)
	profile_button = TextureButton.new()
	home_page.add_child(profile_button)
	profile_button.position = Vector2(830, 450)
	profile_button.size = Vector2(260, 260)
	profile_button.ignore_texture_size = true
	profile_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	profile_button.tooltip_text = "Scegli la foto profilo"
	profile_button.draw.connect(func():
		if profile_texture == null:
			profile_button.draw_circle(Vector2(130, 130), 127, Color("d9d9d9"), true, -1, true)
		profile_button.draw_arc(Vector2(130, 130), 127, 0, TAU, 128, Color.BLACK, 5.0, true)
	)
	var camera_icon := TextureRect.new()
	camera_icon.name = "CameraIcon"
	camera_icon.texture = preload("res://scenes/balatro/trick_asset/ui_bisca/camera.svg")
	camera_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	camera_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	camera_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Set size AFTER disabling the SVG's intrinsic minimum (192px).
	camera_icon.position = Vector2(82, 82)
	camera_icon.size = Vector2(96, 96)
	camera_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_button.add_child(camera_icon)
	profile_button.pressed.connect(func(): profile_picker.open(chosen_name()))
	profile_picker.selected.connect(_set_home_profile)
	_set_home_profile("")
	deck_selector = preload("res://scenes/balatro/scripts/deck_selector.gd").new()
	menu_content.add_child(deck_selector)
	deck_selector.position = Vector2(1500, 420)
	deck_selector.size = Vector2(360, 368)
	name_input = LineEdit.new()
	name_input.virtual_keyboard_enabled = true
	name_input.virtual_keyboard_show_on_focus = true
	name_input.placeholder_text = "COME TI CHIAMI?"
	name_input.max_length = 16
	name_input.custom_minimum_size.x = 360
	name_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_input.custom_minimum_size.y = 58
	name_input.add_theme_font_size_override("font_size", 26)
	_style_input(name_input, 26)
	home_page.add_child(name_input)
	name_input.position = Vector2(780, 680)
	name_input.size = Vector2(360, 64)
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	single_name_input.hide()
	single_name_input.text_changed.connect(func(value):
		name_input.text = value
	)
	match_options = preload("res://scenes/balatro/scripts/match_options.gd").new()
	setup_page.add_child(match_options)
	match_options.setup(self, false)
	bot_slider = match_options.bot_count
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	setup_page.add_child(buttons)
	var back := _button(buttons, "Indietro", show_home)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var play := _button(buttons, "Gioca", _start)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	setup_page.hide()
	_start_title_wave()

func _set_home_profile(avatar: String) -> void:
	profile_avatar = avatar
	profile_texture = preload("res://scenes/balatro/scripts/avatar_data.gd").circular_texture(avatar)
	profile_button.texture_normal = profile_texture
	profile_button.get_node("CameraIcon").visible = profile_texture == null
	profile_button.queue_redraw()

func _show_home_info() -> void:
	var dialog := AcceptDialog.new()
	add_child(dialog)
	dialog.title = "INFO"
	dialog.dialog_text = "SEMI: DENARI > COPPE > SPADE > BASTONI\nSTESSO SEME: VINCE IL NUMERO PIU' ALTO (1–10)\n\nJOLLY: ASSO DI DENARI\nPIU' ALTA: BATTE TUTTI. PIU' BASSA: PERDE CONTRO TUTTI.\n\nDICHIARA LE PRESE CHE FARAI: SE SBAGLI PERDI UNA VITA."
	dialog.get_label().add_theme_font_override("font", KIDS_FONT)
	dialog.get_label().add_theme_font_size_override("font_size", 24)
	dialog.get_label().add_theme_color_override("font_color", BUTTON_TEXT)
	dialog.add_theme_stylebox_override("panel", _menu_button_style(BUTTON_PURPLE))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(1000, 360))

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
	_lock_landscape_web()
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
	button.add_theme_font_size_override("font_size", 28)
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
	_lock_landscape_web()
	start_requested.emit(chosen_name(), int(bot_slider.value) + 1)
