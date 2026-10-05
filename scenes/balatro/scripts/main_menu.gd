extends Control

const KIDS_FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const COUNTER_FONT = KIDS_FONT
const MixedLabel = preload("res://scenes/balatro/scripts/mixed_label.gd")
const ButtonShadow = preload("res://scenes/balatro/scripts/button_shadow.gd")
const RoundedSquareButton = preload("res://scenes/balatro/scripts/rounded_square_button.gd")

# Layout del menu sulla viewport di progetto 1920x1080.
# Modifica questi valori per spostare o ridimensionare gli elementi senza
# dover intervenire sulla gerarchia dei contenitori.
# Layout HOME su base 1920 x 1080: UI a sinistra, personaggio a destra.
# Spostamento comune HOME: positivo verso destra, negativo verso sinistra.
# Include personaggio, foto, nome, titolo/sottotitolo e i due pulsanti di gioco.
const HOME_CONTENT_OFFSET_X := 80.0
const HOME_CONTENT_OFFSET := Vector2(HOME_CONTENT_OFFSET_X, 0)
# Posizione e rotazione INDIPENDENTI dei pulsanti principali.
# Le coordinate sono rispetto alla viewport di progetto 1920x1080.
const PLAY_BUTTON_SIZE := Vector2(450, 118)
const SINGLE_BUTTON_POSITION := Vector2(295, 450) + HOME_CONTENT_OFFSET
const SINGLE_BUTTON_ROTATION := 0.0 # Gradi: es. -5 inclina verso sinistra.
const MULTI_BUTTON_POSITION := Vector2(295, 600) + HOME_CONTENT_OFFSET
const MULTI_BUTTON_ROTATION := 0.0 # Gradi: es. 5 inclina verso destra.
const TITLE_FONT_SIZE := 164
const SUBTITLE_FONT_SIZE := 52
const TITLE_POSITION := Vector2(25, 170) + HOME_CONTENT_OFFSET
const SUBTITLE_POSITION := Vector2(25, 350) + HOME_CONTENT_OFFSET
const TITLE_WIDTH := 1000.0
const HOME_BUTTONS_POSITION := Vector2(70, 785)
const HOME_BUTTONS_SIZE := Vector2(820, 204)
# Inserisci qui il percorso del TUO SVG (o PNG) del personaggio.
const HOME_CHARACTER_PATH := "res://scenes/balatro/resources/personaggio_menu.png"
const SHOP_CHARACTER_PATH := "res://scenes/balatro/resources/personaggio_shop.png"
const HOME_CHARACTER_POSITION := Vector2(600, 150) + HOME_CONTENT_OFFSET
const HOME_CHARACTER_SIZE := Vector2(1320, 1310)
const SOLO_CHARACTER_POSITION := Vector2(-60, 150)
const MULTI_CHARACTER_POSITION := SOLO_CHARACTER_POSITION + Vector2(-150, 0)
var solo_buttons: Array[Button] = []
const SOLO_TITLE_POSITION := Vector2(920, 170)
const SOLO_SUBTITLE_POSITION := Vector2(920, 350)
# Spostamento comune del blocco titolo, creazione ed elenco lobby.
const MULTIPLAYER_CONTENT_OFFSET := Vector2(140, -60)
var solo_transition: Tween
var second_character: TextureRect
var returning_home := false
const SECOND_CHARACTER_POSITION := Vector2(500, 300)
const SECOND_CHARACTER_SIZE := Vector2(800, 1050)
const SETUP_ELEMENTS_POSITION := Vector2(640, 530)
const SETUP_ELEMENTS_SIZE := Vector2(640, 540)
const MENU_BUTTON_HEIGHT := 108.0
const ROUND_BUTTON_SIZE := 108.0
const ROUND_ICON_SIZE := 54.0
# Discord: pulsante circolare in alto a sinistra, sotto INFO.
const DISCORD_BUTTON_SIZE := 108.0
const DISCORD_POSITION := Vector2(40, 40)
const DISCORD_INVITE_URL := "https://discord.gg/ZdRv3gVf8"
# Icona e testo centrati insieme nei pulsanti principali.
const PLAY_ICON_SIZE := 54.0
const PLAY_ICON_TEXT_SPACING := 12.0
# SETTINGS, INFO e SHOP in colonna, in alto a destra (viewport 1920x1080).
const ROUND_BUTTONS_RIGHT_MARGIN := 40.0
const ROUND_BUTTONS_TOP_MARGIN := 160.0
const ROUND_BUTTONS_SPACING := 20.0
# Selettore delle carte nella HOME: sotto MULTIPLAYER, leggermente a destra.
const HOME_DECK_POSITION := Vector2(1520, 600)
const HOME_DECK_SCALE := 1.0
# Foto profilo e campo nome nella HOME, sotto MULTIPLAYER.
# La foto usa una scala ridotta: il pulsante originale misura 260x260.
const HOME_PROFILE_POSITION := Vector2(90, 740) + HOME_CONTENT_OFFSET
const HOME_PROFILE_SCALE := 0.8
const HOME_NAME_POSITION := Vector2(210, 785) + HOME_CONTENT_OFFSET
const HOME_NAME_SIZE := Vector2(690, 174)
const HOME_NAME_TEXT_SHIFT := 20.0 # Pixel verso destra per testo e placeholder, solo HOME
# CONTATORE MONETE: in alto a destra, sopra Settings.
# La posizione e' relativa al bordo destro della viewport.
const COINS_RIGHT_MARGIN := 40.0
const COINS_TOP_MARGIN := 32.0
const COINS_SIZE := Vector2(320, 108) # larghezza totale e altezza del contatore
const COINS_BAR_HEIGHT := 92.0
const COINS_ICON_SIZE := 108.0 # grandezza di coin.png, senza sfondo circolare
const COINS_FONT_SIZE := 48
const COINS_ICON_PATH := "res://scenes/balatro/trick_asset/ui_bisca/coin.png"
const LexispellStyle = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const BUTTON_PURPLE := LexispellStyle.NORMAL
const BUTTON_PURPLE_PRESSED := LexispellStyle.NORMAL
const BUTTON_CYAN := LexispellStyle.HOVER
const BUTTON_DISABLED := LexispellStyle.DISABLED
const BUTTON_TEXT := LexispellStyle.TEXT
const BUTTON_RED := Color(0.909804, 0.364706, 0.407843)

signal start_requested(player_name: String, count: int)

var name_input: LineEdit
var home_page: Control
# Elementi condivisi tra HOME e ingresso MULTIPLAYER. Restano fermi mentre
# i pulsanti principali scorrono via, ma vengono nascosti nella lobby vera.
var home_persistent_ui: Control
var coins_label: Label
var friends_page: Control
var friends_dot: Panel
var username_dot: Panel
var account_default_name := ""
var home_intro_buttons: Array[Button] = []
var home_intro: Tween
# Tempi dell'ingresso pulsanti di Dub Together (pop con leggero rimbalzo).
const HOME_INTRO_DELAY := 0.4
const HOME_INTRO_STAGGER := 0.1
const HOME_INTRO_DURATION := 0.38
var home_character: TextureRect
var profile_picker: Node
var profile_button: TextureButton
var profile_avatar := ""
var profile_texture: Texture2D
var setup_page: Control
var profile_panel: Panel
var single_player_name: Label
var single_player_avatar: TextureRect
var profile_name_timer: Timer
var match_options: PanelContainer
var bot_slider: Range
var single_name_input: LineEdit
var title: Control
var friends_subtitle: Label
var subtitle_slide: Tween
var title_letters: Array[Control] = []
var network_page: Control
var menu_content: Control
var active_page: Control
var settings_page: Control
var shop_page: Control
var home_market_button: TextureButton
var shop_return_page: Control
var personalization_page: Control
var shop_character: TextureRect
var customization_character_ready := false
var deck_selector: Control
const PageTransition = preload("res://scenes/balatro/scripts/page_transition.gd")

func _switch_page(next: Control, backwards := false) -> void:
	_stop_home_intro()
	var previous := active_page if is_instance_valid(active_page) else home_page
	active_page = next
	var network_entry: bool = next == network_page and not bool(network_page.session_controls.visible)
	var show_home_extras: bool = next == home_page
	if is_instance_valid(home_persistent_ui):
		home_persistent_ui.visible = show_home_extras
	if is_instance_valid(home_character):
		home_character.visible = show_home_extras or next == setup_page or network_entry or (next == personalization_page and not customization_character_ready)
	if is_instance_valid(shop_character):
		shop_character.visible = next == personalization_page and customization_character_ready
	# Foto e nome seguono la HOME o il pannello di configurazione.
	if is_instance_valid(profile_button) and is_instance_valid(name_input):
		if show_home_extras:
			_place_profile_home()
		elif next == network_page and network_page.session_controls.visible:
			_place_profile_in_panel()
	if is_instance_valid(deck_selector):
		if show_home_extras:
			_place_deck_selector_home()
		elif next == network_page and network_page.session_controls.visible:
			_place_deck_selector_profile()
		profile_panel.visible = next == network_page and network_page.session_controls.visible
		deck_selector.reset_preview()
	if network_entry or next == home_page or next == setup_page or next == shop_page or next == personalization_page or next == friends_page:
		# L'ingresso Multiplayer usa solo il pop dei pulsanti, senza traslare la pagina.
		if has_meta("page_transition_cleanup"):
			get_meta("page_transition_cleanup").call()
		if is_instance_valid(previous) and previous != next:
			previous.hide()
		next.show()
	else:
		PageTransition.slide(self, previous, next, backwards)
	if next == home_page:
		_play_home_intro()
	if subtitle_slide and subtitle_slide.is_valid():
		subtitle_slide.kill()
	if next == setup_page or network_entry or next == home_page:
		return
	var subtitle_x := SUBTITLE_POSITION.x
	friends_subtitle.position.x = subtitle_x
	if previous != next and friends_subtitle.visible and next != network_page:
		friends_subtitle.position.x = subtitle_x + get_viewport_rect().size.x * (-1.0 if backwards else 1.0)
		subtitle_slide = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		subtitle_slide.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		subtitle_slide.tween_property(friends_subtitle, "position:x", subtitle_x, 0.35)

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
	friends_subtitle = preload("res://scenes/balatro/scripts/idle_subtitle.gd").new()
	menu_content.add_child(friends_subtitle)
	friends_subtitle.text = "WITH YOUR FRIENDS"
	friends_subtitle.position = SUBTITLE_POSITION
	friends_subtitle.size = Vector2(TITLE_WIDTH, 58)
	friends_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	friends_subtitle.add_theme_font_override("font", KIDS_FONT)
	friends_subtitle.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	friends_subtitle.add_theme_color_override("font_color", BUTTON_TEXT)
	friends_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	friends_subtitle.relief_shadow = true
	friends_subtitle.add_theme_color_override("font_shadow_color", Color("0c0918"))
	friends_subtitle.add_theme_constant_override("shadow_offset_x", 0)
	friends_subtitle.add_theme_constant_override("shadow_offset_y", 5)
	friends_subtitle.set_animated(true)
	friends_subtitle.show()
	home_page = Control.new()
	menu_content.add_child(home_page)
	home_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# SVG decorativo: figlio della HOME, quindi sparisce su altre pagine.
	# ResourceLoader.exists evita di bloccare il menu finché non aggiungi il file.
	if ResourceLoader.exists(HOME_CHARACTER_PATH):
		var mascot := TextureRect.new()
		home_character = mascot
		mascot.name = "HomeCharacter"
		mascot.texture = load(HOME_CHARACTER_PATH) as Texture2D
		mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mascot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mascot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu_content.add_child(mascot)
		mascot.position = HOME_CHARACTER_POSITION
		mascot.size = HOME_CHARACTER_SIZE
	shop_character = TextureRect.new()
	shop_character.name = "ShopCharacter"
	shop_character.texture = load(SHOP_CHARACTER_PATH) as Texture2D
	shop_character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shop_character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shop_character.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	shop_character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_character.position = HOME_CHARACTER_POSITION + Vector2(0, 0)
	shop_character.size = HOME_CHARACTER_SIZE * 1.1
	shop_character.pivot_offset = shop_character.size * 0.5
	shop_character.rotation_degrees = 0.0
	shop_character.hide()
	menu_content.add_child(shop_character)
	# Mantieni i pulsanti della HOME sopra il disegno decorativo.
	second_character = TextureRect.new()
	second_character.texture = preload("res://scenes/balatro/resources/p2_menu.png")
	second_character.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	second_character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	second_character.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	second_character.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_content.add_child(second_character)
	second_character.size = SECOND_CHARACTER_SIZE
	second_character.hide()
	if is_instance_valid(home_character):
		menu_content.move_child(second_character, home_character.get_index())
	menu_content.move_child(home_page, menu_content.get_child_count() - 1)
	# Profilo, nome, monete, scorciatoie e selettore mazzo non fanno parte
	# della pagina che scorre: sono condivisi con l'ingresso MULTIPLAYER.
	home_persistent_ui = Control.new()
	home_persistent_ui.name = "HomePersistentUI"
	menu_content.add_child(home_persistent_ui)
	home_persistent_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_persistent_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# I due pulsanti sono indipendenti: coordinate e rotazione separate.
	var single := _button(home_page, "SINGLEPLAYER", show_setup)
	single.position = SINGLE_BUTTON_POSITION
	single.size = PLAY_BUTTON_SIZE
	single.pivot_offset = PLAY_BUTTON_SIZE / 2.0
	single.rotation_degrees = SINGLE_BUTTON_ROTATION
	_add_button_icon(single, "res://scenes/balatro/trick_asset/ui_bisca/single.svg")
	_set_play_button_radius(single)
	_add_gloss_button_style(single)

	var multi := _button(home_page, "MULTIPLAYER", _show_network)
	multi.position = MULTI_BUTTON_POSITION
	multi.size = PLAY_BUTTON_SIZE
	multi.pivot_offset = PLAY_BUTTON_SIZE / 2.0
	multi.rotation_degrees = MULTI_BUTTON_ROTATION
	_add_button_icon(multi, "res://scenes/balatro/trick_asset/ui_bisca/multi.svg")
	_set_play_button_radius(multi)
	_add_gloss_button_style(multi)

	# Contatore monete non cliccabile, sopra il pulsante Shop.
	_build_coin_counter(home_persistent_ui)
	var account_profile := get_node("/root/AccountProfile")
	account_profile.changed.connect(_refresh_account_coins)
	_refresh_account_coins()

	# Pulsanti circolari indipendenti in alto a destra: SHOP, SETTINGS, INFO.
	var round_buttons := Control.new()
	preload("res://scenes/balatro/scripts/safe_edges.gd").attach.call_deferred(round_buttons, true)
	home_persistent_ui.add_child(round_buttons)
	round_buttons.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	round_buttons.offset_left = -ROUND_BUTTON_SIZE - ROUND_BUTTONS_RIGHT_MARGIN
	round_buttons.offset_top = ROUND_BUTTONS_TOP_MARGIN
	round_buttons.offset_right = -ROUND_BUTTONS_RIGHT_MARGIN
	round_buttons.offset_bottom = ROUND_BUTTONS_TOP_MARGIN + ROUND_BUTTON_SIZE * 3.0 + ROUND_BUTTONS_SPACING * 2.0
	var shop := _round_icon_button(round_buttons, "brush.svg", "Personalizza e Shop", _show_personalization)
	shop.position = Vector2.ZERO
	shop.size = Vector2.ONE * ROUND_BUTTON_SIZE
	var settings := _round_icon_button(round_buttons, "setting.svg", "Settings", _show_settings)
	settings.position = Vector2(0, ROUND_BUTTON_SIZE + ROUND_BUTTONS_SPACING)
	settings.size = Vector2.ONE * ROUND_BUTTON_SIZE
	username_dot = _notification_dot(settings)
	account_profile.changed.connect(_refresh_username_dot)
	get_node("/root/AccountSession").changed.connect(_refresh_username_dot)
	_refresh_username_dot()
	var friends := _round_icon_button(round_buttons, "friends.svg", "Amici", _show_friends)
	friends.position = Vector2(0, (ROUND_BUTTON_SIZE + ROUND_BUTTONS_SPACING) * 2.0)
	friends.size = Vector2.ONE * ROUND_BUTTON_SIZE
	friends_dot = Panel.new()
	friends.add_child(friends_dot)
	friends_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	friends_dot.position = Vector2(ROUND_BUTTON_SIZE - 24, 0)
	friends_dot.size = Vector2(22,22)
	var dot_style := StyleBoxFlat.new()
	dot_style.bg_color = Color("ed4155")
	dot_style.set_corner_radius_all(11)
	friends_dot.add_theme_stylebox_override("panel",dot_style)
	get_node("/root/FriendsManager").changed.connect(_refresh_friends_dot)
	_refresh_friends_dot()
	var market_button := TextureButton.new()
	home_market_button = market_button
	market_button.name = "HomeShop"
	home_page.add_child(market_button)
	market_button.texture_normal = preload("res://scenes/balatro/trick_asset/ui_bisca/tastoShop.png")
	market_button.ignore_texture_size = true
	market_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	market_button.size = preload("res://scenes/balatro/scripts/personalization_page.gd").SHOP_BUTTON_SIZE
	market_button.position = Vector2(1920, 1080) - Vector2(40, 40) - market_button.size
	market_button.pivot_offset = market_button.size / 2.0
	market_button.set_meta("safe_bottom", true)
	preload("res://scenes/balatro/scripts/safe_edges.gd").attach(market_button, true)
	market_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	market_button.pressed.connect(_show_shop)
	preload("res://scenes/balatro/scripts/button_audio.gd").attach(market_button)
	var hover_state := {"tween": null}
	var hover := func(active: bool):
		if hover_state.tween and hover_state.tween.is_valid():
			hover_state.tween.kill()
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		hover_state.tween = tween
		var ratio := clampf(128.0 / market_button.size.x, 0.5, 1.0)
		tween.tween_property(market_button, "scale", Vector2.ONE * (1.0 + 0.2 * ratio if active else 1.0), 0.2 if active else 0.25)
		tween.parallel().tween_property(market_button, "rotation_degrees", 5.0 * ratio * [-1.0, 1.0].pick_random() if active else 0.0, 0.1)
		if active:
			tween.tween_property(market_button, "rotation_degrees", 0.0, 0.1)
	market_button.mouse_entered.connect(hover.bind(true))
	market_button.mouse_exited.connect(hover.bind(false))
	market_button.focus_entered.connect(hover.bind(true))
	market_button.focus_exited.connect(hover.bind(false))

	# I pulsanti mantengono l'animazione d'ingresso e hover esistente.
	# Control separati: nessun Container forza le loro dimensioni.
	for button in [single, multi, shop, settings, friends]:
		_add_gloss_button_style(button)
		home_intro_buttons.append(button)
	profile_picker = preload("res://scenes/balatro/scripts/profile_picker.gd").new()
	add_child(profile_picker)
	profile_button = TextureButton.new()
	home_persistent_ui.add_child(profile_button)
	profile_button.position = Vector2(110, 390)
	profile_button.size = Vector2(260, 260)
	profile_button.ignore_texture_size = true
	profile_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	profile_button.tooltip_text = "Scegli la foto profilo"
	profile_button.draw.connect(func():
		if profile_texture == null:
			profile_button.draw_circle(Vector2(130, 135), 127, Color(0.047059, 0.035294, 0.094118, 0.28), true, -1, true)
			profile_button.draw_circle(Vector2(130, 130), 127, LexispellStyle.MUTED_TEXT, true, -1, true)
			profile_button.draw_arc(Vector2(130, 130), 119, 0.12 * PI, 0.88 * PI, 64, Color(0, 0, 0, 0.26), 9, true)
			profile_button.draw_arc(Vector2(130, 130), 121, 1.12 * PI, 1.88 * PI, 64, Color(1, 1, 1, 0.8), 4, true)
		profile_button.draw_arc(Vector2(130, 130), 127, 0, TAU, 128, Color("0c0918") if profile_texture == null else Color.BLACK, 5.0, true)
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
	deck_selector.position = Vector2(515, 375)
	deck_selector.size = Vector2(360, 368)
	for child in deck_selector.get_children():
		if child is Button:
			_add_gloss_button_style(child)
	name_input = LineEdit.new()
	name_input.virtual_keyboard_enabled = true
	name_input.virtual_keyboard_show_on_focus = true
	name_input.placeholder_text = "COME TI CHIAMI?"
	name_input.max_length = 16
	name_input.custom_minimum_size.x = 360
	name_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_input.custom_minimum_size.y = 58
	name_input.add_theme_font_size_override("font_size", 46)
	_style_input(name_input, 46)
	home_persistent_ui.add_child(name_input)
	name_input.position = Vector2(60, 665)
	name_input.size = Vector2(360, 64)
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_name_gloss_style()
	setup_page = Control.new()
	menu_content.add_child(setup_page)
	setup_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	setup_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	single_name_input = LineEdit.new()
	single_name_input.virtual_keyboard_enabled = true
	single_name_input.virtual_keyboard_show_on_focus = true
	single_name_input.placeholder_text = "COME TI CHIAMI?"
	single_name_input.max_length = 16
	single_name_input.custom_minimum_size.x = 520
	single_name_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	single_name_input.custom_minimum_size.y = 72
	_style_input(single_name_input, 36)
	setup_page.add_child(single_name_input)
	single_name_input.hide()
	single_name_input.text_changed.connect(func(value):
		name_input.text = value
	)
	match_options = preload("res://scenes/balatro/scripts/match_options.gd").new()
	setup_page.add_child(match_options)
	match_options.setup(self, false)
	match_options.position = Vector2(1090, 440)
	match_options.size = Vector2(660, 280)
	bot_slider = match_options.bot_count
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 24)
	setup_page.add_child(buttons)
	buttons.position = Vector2(1290, 795)
	buttons.size = Vector2(260, 96)
	var back := _button(setup_page, "Indietro", show_home)
	back.set_meta("safe_bottom", false)
	back.position = Vector2(40, 40)
	back.size = Vector2(260, 96)
	var play := _button(buttons, "Gioca", _start)
	solo_buttons = [back, play]
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for button in [back, play]:
		button.custom_minimum_size = Vector2(260, 96)
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
			if style:
				style.set_corner_radius_all(48)
				button.add_theme_stylebox_override(state, style)
	setup_page.hide()
	_build_mode_profile()
	_place_profile_home() # Foto e nome visibili sotto Multiplayer già all'avvio.
	_place_deck_selector_home() # Visibile già al primo avvio della HOME.
	var participants := Panel.new()
	setup_page.add_child(participants)
	participants.hide()
	participants.position = Vector2(990, 140)
	participants.size = Vector2(840, 720)
	participants.add_theme_stylebox_override("panel", _menu_button_style(LexispellStyle.PANEL, BUTTON_CYAN, 4))
	var heading := Label.new()
	participants.add_child(heading)
	heading.text = "GIOCATORI"
	heading.position = Vector2(30, 24)
	heading.add_theme_font_override("font", KIDS_FONT)
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", BUTTON_TEXT)
	var slot := Panel.new()
	participants.add_child(slot)
	slot.position = Vector2(30, 90)
	slot.size = Vector2(780, 90)
	slot.add_theme_stylebox_override("panel", _menu_button_style(BUTTON_PURPLE))
	single_player_avatar = TextureRect.new()
	slot.add_child(single_player_avatar)
	single_player_avatar.position = Vector2(16, 12)
	single_player_avatar.size = Vector2(66, 66)
	single_player_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	single_player_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	single_player_avatar.draw.connect(func():
		if single_player_avatar.texture == null:
			single_player_avatar.draw_circle(Vector2(33, 33), 32, Color("efecfa"), true, -1, true)
	)
	single_player_name = Label.new()
	slot.add_child(single_player_name)
	single_player_name.position = Vector2(104, 22)
	single_player_name.add_theme_font_override("font", KIDS_FONT)
	single_player_name.add_theme_font_size_override("font_size", 30)
	single_player_name.add_theme_color_override("font_color", BUTTON_TEXT)
	name_input.text_changed.connect(func(_value): _refresh_single_profile())
	profile_name_timer = Timer.new()
	profile_name_timer.one_shot = true
	profile_name_timer.wait_time = 0.35
	add_child(profile_name_timer)
	profile_name_timer.timeout.connect(_send_profile_name)
	name_input.text_changed.connect(func(_value): profile_name_timer.start())
	name_input.focus_exited.connect(_send_profile_name)
	name_input.text_submitted.connect(func(_value): _send_profile_name())
	_refresh_single_profile()
	get_node("/root/AccountProfile").changed.connect(_refresh_default_name)
	_refresh_default_name()
	_start_title_wave()
	_play_home_intro()

func _stop_home_intro() -> void:
	if home_intro and home_intro.is_valid():
		home_intro.kill()
	if is_instance_valid(home_market_button):
		home_market_button.scale = Vector2.ONE
		home_market_button.mouse_filter = Control.MOUSE_FILTER_STOP
		home_market_button.focus_mode = Control.FOCUS_ALL
	for button in home_intro_buttons:
		button.scale = Vector2.ONE
		button.modulate.a = 1.0
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.focus_mode = Control.FOCUS_ALL
		button.hover_animate = true
	# Ripristina anche i tre elementi aggiunti all'animazione HOME.
	# Le scale del profilo e del mazzo devono restare quelle configurate.
	if is_instance_valid(profile_button) and profile_button.get_parent() == home_persistent_ui:
		profile_button.scale = Vector2.ONE * HOME_PROFILE_SCALE
		profile_button.mouse_filter = Control.MOUSE_FILTER_STOP
		profile_button.focus_mode = Control.FOCUS_ALL
	if is_instance_valid(name_input) and name_input.get_parent() == home_persistent_ui:
		name_input.scale = Vector2.ONE
		name_input.mouse_filter = Control.MOUSE_FILTER_STOP
		name_input.focus_mode = Control.FOCUS_ALL
	if is_instance_valid(deck_selector) and deck_selector.get_parent() == home_persistent_ui:
		deck_selector.scale = Vector2.ONE * HOME_DECK_SCALE

func _play_home_intro() -> void:
	_stop_home_intro()
	_home_pop_buttons(home_intro_buttons)
	_animate_home_extras()

func _home_pop_buttons(buttons: Array[Button]) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	home_intro = tween
	for index in buttons.size():
		var button: Button = buttons[index]
		if button.hover_tween and button.hover_tween.is_valid():
			button.hover_tween.kill()
		# Non azzerare la rotazione: Singleplayer e Multiplayer la mantengono.
		button.pivot_offset = button.size / 2.0
		button.hover_animate = false
		button.release_focus()
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
		button.scale = Vector2.ZERO
		button.modulate.a = 0.0
		var delay := HOME_INTRO_DELAY + index * HOME_INTRO_STAGGER
		tween.tween_callback(func(): button.modulate.a = 1.0).set_delay(delay)
		tween.tween_property(button, "scale", Vector2.ONE, HOME_INTRO_DURATION).from(Vector2.ZERO).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.focus_mode = Control.FOCUS_ALL
			button.hover_animate = true
		).set_delay(delay + HOME_INTRO_DURATION)

func animate_buttons_like_home(buttons: Array[Button]) -> void:
	_home_pop_buttons(buttons)

func _animate_home_extras() -> void:
	# Foto, nome e selettore mazzo entrano con lo stesso effetto pop,
	# dopo i pulsanti (con leggero ritardo fra loro).
	var home_extras: Array[Control] = [profile_button, name_input, deck_selector, home_market_button]
	for index in home_extras.size():
		var control: Control = home_extras[index]
		if control.get_parent() != home_persistent_ui and control != home_market_button:
			continue
		var final_scale := Vector2.ONE
		if control == profile_button:
			final_scale = Vector2.ONE * HOME_PROFILE_SCALE
		elif control == deck_selector:
			final_scale = Vector2.ONE * HOME_DECK_SCALE
		control.pivot_offset = control.size / 2.0
		# Evita interazioni premature mentre l'elemento appare.
		if control == profile_button or control == name_input or control == home_market_button:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			control.focus_mode = Control.FOCUS_NONE
		control.scale = Vector2.ZERO
		var delay := HOME_INTRO_DELAY + (home_intro_buttons.size() + index) * HOME_INTRO_STAGGER
		home_intro.tween_property(control, "scale", final_scale, HOME_INTRO_DURATION).from(Vector2.ZERO).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if control == profile_button or control == name_input or control == home_market_button:
			home_intro.tween_callback(func():
				if is_instance_valid(control):
					control.mouse_filter = Control.MOUSE_FILTER_STOP
					control.focus_mode = Control.FOCUS_ALL
			).set_delay(delay + HOME_INTRO_DURATION)

func _build_mode_profile() -> void:
	profile_panel = Panel.new()
	menu_content.add_child(profile_panel)
	profile_panel.position = Vector2(60, 140)
	profile_panel.size = Vector2(870, 790)
	profile_panel.add_theme_stylebox_override("panel", _menu_button_style(LexispellStyle.PANEL, BUTTON_CYAN, 4))
	profile_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_content.move_child(profile_panel, 0)
	_place_profile_in_panel()
	_place_deck_selector_profile()
	profile_panel.hide()

# Stessi controlli, riposizionati senza duplicarli.
func _place_profile_home() -> void:
	if profile_button.get_parent() != home_persistent_ui:
		profile_button.reparent(home_persistent_ui, false)
	profile_button.position = HOME_PROFILE_POSITION
	profile_button.scale = Vector2.ONE * HOME_PROFILE_SCALE
	if name_input.get_parent() != home_persistent_ui:
		name_input.reparent(home_persistent_ui, false)
	name_input.position = HOME_NAME_POSITION
	name_input.size = HOME_NAME_SIZE
	_set_name_text_shift(true)
	# Foto sopra il campo nome anche quando i due elementi si sovrappongono.
	profile_button.z_index = 1
	home_persistent_ui.move_child(profile_button, home_persistent_ui.get_child_count() - 1)

func _place_profile_in_panel() -> void:
	if profile_button.get_parent() != profile_panel:
		profile_button.reparent(profile_panel, false)
	profile_button.position = Vector2(35, 25)
	profile_button.scale = Vector2(0.5, 0.5)
	if name_input.get_parent() != profile_panel:
		name_input.reparent(profile_panel, false)
	name_input.position = Vector2(190, 60)
	name_input.size = Vector2(570, 64)
	_set_name_text_shift(false)
	# Mantiene la stessa priorita anche nel pannello di configurazione.
	profile_button.z_index = 1
	profile_panel.move_child(profile_button, profile_panel.get_child_count() - 1)

# Il selettore viene spostato tra HOME e pannello partita senza duplicarlo.
func _place_deck_selector_home() -> void:
	if deck_selector.get_parent() != home_persistent_ui:
		deck_selector.reparent(home_persistent_ui, false)
	deck_selector.position = HOME_DECK_POSITION
	deck_selector.scale = Vector2.ONE * HOME_DECK_SCALE
	deck_selector.hide()

# Chiamate dalla pagina multiplayer quando si entra/esce dalla lobby reale.
func show_network_entry_extras() -> void:
	profile_panel.hide()
	_place_profile_home()
	_place_deck_selector_home()
	home_persistent_ui.hide()
	if is_instance_valid(home_character):
		home_character.show()

func hide_network_entry_extras() -> void:
	home_persistent_ui.hide()
	second_character.hide()

func _place_deck_selector_profile() -> void:
	deck_selector.show()
	if deck_selector.get_parent() != profile_panel:
		deck_selector.reparent(profile_panel, false)
	deck_selector.position = Vector2(485, 270)
	deck_selector.scale = Vector2(0.85, 0.85)

func _refresh_single_profile() -> void:
	if is_instance_valid(single_player_name):
		single_player_name.text = chosen_name() + "   · TU"
		single_player_avatar.texture = profile_texture
		single_player_avatar.queue_redraw()
	if is_instance_valid(network_page):
		network_page.refresh_own_card()

func _send_profile_name() -> void:
	profile_name_timer.stop()
	if is_instance_valid(network_page) and network_page.is_visible_in_tree() and network_page.session_controls.visible:
		get_node("/root/NetworkSession").send({"op": "rename", "name": chosen_name()})

func _set_home_profile(avatar: String) -> void:
	profile_avatar = avatar
	profile_texture = preload("res://scenes/balatro/scripts/avatar_data.gd").circular_texture(avatar)
	profile_button.texture_normal = profile_texture
	profile_button.get_node("CameraIcon").visible = profile_texture == null
	profile_button.queue_redraw()
	_refresh_single_profile()
	if is_instance_valid(network_page) and network_page.is_visible_in_tree() and network_page.session_controls.visible:
		get_node("/root/NetworkSession").send({"op": "profile", "avatar": avatar})

func _open_discord() -> void:
	OS.shell_open(DISCORD_INVITE_URL)


func _show_home_info() -> void:
	var dialog := AcceptDialog.new()
	add_child(dialog)
	dialog.title = "INFO"
	dialog.dialog_text = "SEMI: DENARI > COPPE > SPADE > BASTONI\nSTESSO SEME: VINCE IL NUMERO PIU' ALTO (1–10)\n\nJOLLY: ASSO DI DENARI\nPIU' ALTA: BATTE TUTTI. PIU' BASSA: PERDE CONTRO TUTTI.\n\nDICHIARA LE PRESE CHE FARAI: SE SBAGLI PERDI UNA VITA."
	dialog.get_label().add_theme_font_override("font", KIDS_FONT)
	dialog.get_label().add_theme_font_size_override("font_size", 24)
	dialog.get_label().add_theme_color_override("font_color", BUTTON_TEXT)
	dialog.add_theme_stylebox_override("panel", _menu_button_style(LexispellStyle.PANEL))
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(1000, 360))

func _process(delta: float) -> void:
	# La partita nasconde il menu: non serve calcolare il suo parallax.
	if not is_visible_in_tree():
		return
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
	_animate_mode_heading("WITH YOUR FRIENDS")

func _refresh_friends_dot() -> void:
	if is_instance_valid(friends_dot):
		friends_dot.visible = get_node("/root/FriendsManager").pending_count() > 0

static func _notification_dot(button: Control) -> Panel:
	var dot := Panel.new()
	dot.name = "UsernameNotification"
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(dot)
	dot.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	dot.offset_left = -24
	dot.offset_right = -2
	dot.offset_top = 0
	dot.offset_bottom = 22
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ed4155")
	style.set_corner_radius_all(11)
	dot.add_theme_stylebox_override("panel", style)
	return dot

func _refresh_username_dot() -> void:
	if is_instance_valid(username_dot):
		username_dot.visible = get_node("/root/AccountProfile").needs_username()

func _show_friends() -> void:
	title.hide()
	friends_subtitle.hide()
	if not is_instance_valid(friends_page):
		friends_page = preload("res://scenes/balatro/scripts/friends_page.gd").new()
		add_child(friends_page)
		friends_page.setup(self)
	_switch_page(friends_page)
	friends_page.open()

func _show_personalization() -> void:
	title.hide()
	friends_subtitle.hide()
	if not is_instance_valid(personalization_page):
		personalization_page = preload("res://scenes/balatro/scripts/personalization_page.gd").new()
		add_child(personalization_page)
		personalization_page.setup(self)
	_switch_page(personalization_page)
	personalization_page.open()
	_enter_customization_character()

func _show_shop() -> void:
	shop_return_page = active_page
	title.hide()
	friends_subtitle.hide()
	if not is_instance_valid(shop_page):
		shop_page = preload("res://scenes/balatro/scripts/shop_page.gd").new()
		add_child(shop_page)
		shop_page.setup(self)
	_switch_page(shop_page)
	shop_page.open()
	if is_instance_valid(shop_character):
		shop_character.hide()

func _leave_shop() -> void:
	if shop_return_page == home_page:
		show_home()
	else:
		_show_personalization()


func _show_settings() -> void:
	title.hide()
	friends_subtitle.hide()
	if not is_instance_valid(settings_page):
		settings_page = preload("res://scenes/balatro/scripts/settings_page.gd").new()
		add_child(settings_page)
		settings_page.setup(self)
	_switch_page(settings_page)

func _show_menu_title(with_friends: bool = false) -> void:
	second_character.hide()
	if solo_transition and solo_transition.is_valid():
		solo_transition.kill()
	title.show()
	title.modulate.a = 1.0
	friends_subtitle.modulate.a = 1.0
	friends_subtitle.scale = Vector2.ONE
	if is_instance_valid(home_character):
		home_character.texture = load(HOME_CHARACTER_PATH) as Texture2D
		home_character.show()
		home_character.position = HOME_CHARACTER_POSITION
		home_character.modulate.a = 1.0
	if is_instance_valid(shop_character):
		shop_character.hide()
		shop_character.position = HOME_CHARACTER_POSITION
		shop_character.modulate.a = 1.0
	customization_character_ready = false
	friends_subtitle.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	friends_subtitle.text = "WITH YOUR FRIENDS"
	friends_subtitle.position = SUBTITLE_POSITION
	friends_subtitle.size.x = TITLE_WIDTH
	friends_subtitle.set_animated(with_friends)
	friends_subtitle.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	title.scale = Vector2.ONE
	title.position = TITLE_POSITION
	friends_subtitle.visible = with_friends

func _label(parent: Node, text: String, font_size: int) -> MixedLabel:
	var label := MixedLabel.new()
	label.set_mixed_text(text)
	label.add_theme_font_override("normal_font", KIDS_FONT)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("font_color", LexispellStyle.TEXT)
	parent.add_child(label)
	return label

func _build_title(parent: Control) -> void:
	title = Control.new()
	title.position = TITLE_POSITION
	title.size = Vector2(TITLE_WIDTH, TITLE_FONT_SIZE + 30.0)
	parent.add_child(title)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", -8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)
	var title_font := KIDS_FONT
	for character in "BISCA":
		var letter := Control.new()
		var width := title_font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_FONT_SIZE).x
		letter.custom_minimum_size = Vector2(width + 14, TITLE_FONT_SIZE + 30.0)
		letter.pivot_offset = letter.custom_minimum_size / 2.0
		row.add_child(letter)
		var outer := Label.new()
		outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		outer.text = character
		outer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		outer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		outer.add_theme_font_override("font", title_font)
		outer.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
		outer.add_theme_color_override("font_color", LexispellStyle.TEXT)
		outer.add_theme_color_override("font_outline_color", LexispellStyle.HOVER)
		outer.add_theme_constant_override("outline_size", 16)
		outer.add_theme_color_override("font_shadow_color", Color("0c0918"))
		outer.add_theme_constant_override("shadow_offset_x", 0)
		outer.add_theme_constant_override("shadow_offset_y", 7)
		outer.add_theme_constant_override("shadow_outline_size", 16)
		letter.add_child(outer)
		var inner := Label.new()
		inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner.text = character
		inner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		inner.add_theme_font_override("font", title_font)
		inner.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
		inner.add_theme_color_override("font_color", LexispellStyle.TEXT)
		inner.add_theme_color_override("font_outline_color", LexispellStyle.HOVER)
		inner.add_theme_constant_override("outline_size", 24)
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

# Sposta soltanto il testo di nome e placeholder senza spostare il box.
# Con allineamento CENTER, 2 pixel di margine sinistro producono circa
# 1 pixel di spostamento del centro del testo verso destra.
# Nel pannello partita ripristina il centramento normale.
func _set_name_text_shift(in_home: bool) -> void:
	var shift := HOME_NAME_TEXT_SHIFT if in_home else 0.0
	for state in ["normal", "focus"]:
		var base := name_input.get_theme_stylebox(state)
		if base is StyleBoxFlat:
			var modified := (base as StyleBoxFlat).duplicate() as StyleBoxFlat
			modified.content_margin_left = 16.0 + shift * 2.0
			modified.content_margin_right = 16.0
			name_input.add_theme_stylebox_override(state, modified)

func _style_input(input: LineEdit, font_size: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = LexispellStyle.PANEL
	style.border_color = Color("2a2438")
	style.set_border_width_all(2)
	# Il campo nome HOME e profilo ha estremita a capsula (raggio = altezza / 2).
	style.set_corner_radius_all(int(HOME_NAME_SIZE.y / 2.0) if input == name_input else 10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	input.add_theme_stylebox_override("normal", style)
	var focus_style := style.duplicate()
	focus_style.border_color = LexispellStyle.HOVER
	input.add_theme_stylebox_override("focus", focus_style)
	input.add_theme_font_override("font", KIDS_FONT)
	input.add_theme_font_size_override("font_size", font_size)
	input.add_theme_color_override("font_color", LexispellStyle.TEXT)
	input.add_theme_color_override("font_placeholder_color", LexispellStyle.MUTED_TEXT)
	input.add_theme_color_override("caret_color", LexispellStyle.TEXT)

func match_singleplayer_back(button: Button) -> void:
	# Un solo riferimento per dimensioni, stile e posizione di tutti gli Indietro.
	var reference: Button = solo_buttons[0]
	button.set_meta("safe_bottom", false)
	button.custom_minimum_size = reference.custom_minimum_size
	button.size = reference.size
	button.position = reference.position - Vector2(reference.get_meta("safe_edge", Vector2.ZERO)) + Vector2(button.get_meta("safe_edge", Vector2.ZERO))
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, reference.get_theme_stylebox(state).duplicate())


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := RoundedSquareButton.new()
	button.text = text.to_upper()
	button.custom_minimum_size.y = MENU_BUTTON_HEIGHT
	button.add_theme_font_override("font", KIDS_FONT)
	button.add_theme_font_size_override("font_size", 36)
	button.add_theme_stylebox_override("normal", _menu_button_style(BUTTON_PURPLE, Color.TRANSPARENT, 0, MENU_BUTTON_HEIGHT))
	button.add_theme_stylebox_override("hover", _menu_button_style(BUTTON_CYAN, BUTTON_TEXT, 6, MENU_BUTTON_HEIGHT))
	button.add_theme_stylebox_override("pressed", _menu_button_style(BUTTON_PURPLE_PRESSED, BUTTON_TEXT, 2, MENU_BUTTON_HEIGHT))
	button.add_theme_stylebox_override("disabled", _menu_button_style(BUTTON_DISABLED, Color.TRANSPARENT, 0, MENU_BUTTON_HEIGHT))
	button.add_theme_color_override("font_color", BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", BUTTON_TEXT)
	button.add_theme_color_override("font_pressed_color", BUTTON_TEXT)
	button.add_theme_color_override("font_disabled_color", LexispellStyle.DISABLED_TEXT)
	parent.add_child(button)
	if text.to_lower() == "indietro":
		button.set_meta("safe_bottom", true)
		preload("res://scenes/balatro/scripts/safe_edges.gd").attach(button)
	button.pressed.connect(callback)
	return button

# Pulsanti principali HOME e ingresso MULTIPLAYER: estremità a capsula.
# Il radius segue automaticamente metà dell'altezza impostata in PLAY_BUTTON_SIZE.
func _add_gloss_button_style(button: Button) -> void:
	preload("res://scenes/balatro/scripts/cartoon_button_style.gd").attach(button)

func _add_name_gloss_style() -> void:
	# This remains a LineEdit: keyboard, caret and text saving are unchanged.
	var style := name_input.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.bg_color = Color("38315a")
	style.border_color = Color("0c0918")
	style.set_border_width_all(4)
	style.border_width_bottom = 8
	style.set_corner_radius_all(int(name_input.size.y * 0.5))
	style.corner_detail = 20
	style.anti_aliasing_size = 1.4
	style.shadow_color = Color(0.047059, 0.035294, 0.094118, 0.28)
	style.shadow_size = 1
	style.shadow_offset = Vector2(0, 5)
	name_input.add_theme_stylebox_override("normal", style)
	var bevel := preload("res://scenes/balatro/scripts/button_bevel.gd").new()
	name_input.add_child(bevel)
	bevel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gloss := preload("res://scenes/balatro/scripts/button_gloss.gd").new()
	gloss.gloss_color = Color(1, 1, 1, 0.28)
	name_input.add_child(gloss)
	gloss.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var refresh := func():
		var normal := name_input.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		normal.set_corner_radius_all(int(name_input.size.y * 0.5))
		name_input.add_theme_stylebox_override("normal", normal)
		bevel.visible = not name_input.has_focus()
		gloss.visible = not name_input.has_focus()
	name_input.resized.connect(refresh)
	name_input.focus_entered.connect(refresh)
	name_input.focus_exited.connect(refresh)


func _set_play_button_radius(button: Button) -> void:
	var radius := int(PLAY_BUTTON_SIZE.y / 2.0)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var base_style := button.get_theme_stylebox(state)
		if base_style is StyleBoxFlat:
			var style := (base_style as StyleBoxFlat).duplicate() as StyleBoxFlat
			style.set_corner_radius_all(radius)
			button.add_theme_stylebox_override(state, style)


# Pulsanti tondi SETTINGS / INFO / SHOP: stessi stili e animazioni degli altri pulsanti.
func _round_icon_button(parent: Node, filename: String, tooltip: String, callback: Callable) -> Button:
	var button := _button(parent, "", callback)
	button.custom_minimum_size = Vector2(ROUND_BUTTON_SIZE, ROUND_BUTTON_SIZE)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.tooltip_text = tooltip
	# Raggio pari a metà lato: pulsante perfettamente circolare.
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var color := BUTTON_CYAN if state in ["hover", "focus"] else BUTTON_DISABLED if state == "disabled" else BUTTON_PURPLE
		var style := _menu_button_style(color)
		style.set_corner_radius_all(int(ROUND_BUTTON_SIZE / 2.0))
		button.add_theme_stylebox_override(state, style)
	var path := "res://scenes/balatro/trick_asset/ui_bisca/" + filename
	if ResourceLoader.exists(path):
		var icon := TextureRect.new()
		icon.texture = load(path) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		icon.set_anchors_preset(Control.PRESET_CENTER)
		var half := ROUND_ICON_SIZE / 2.0
		icon.offset_left = -half
		icon.offset_top = -half
		icon.offset_right = half
		icon.offset_bottom = half
	else:
		push_warning("Icona pulsante non trovata: " + path)
	return button


# Icona e testo sono un unico gruppo, centrato nel pulsante.
# Il contenitore segue automaticamente scala, pop e hover del pulsante.
func _add_button_icon(button: Button, path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Icona del pulsante non trovata: " + path)
		return

	var caption := button.text
	button.text = "" # Evita che il testo predefinito venga centrato da solo.

	var center := CenterContainer.new()
	center.name = "CenteredIconAndText"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", int(PLAY_ICON_TEXT_SPACING))
	center.add_child(content)

	var icon := TextureRect.new()
	icon.texture = load(path) as Texture2D
	icon.custom_minimum_size = Vector2.ONE * PLAY_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)

	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.add_theme_font_override("font", KIDS_FONT)
	caption_label.add_theme_font_size_override("font_size", 36)
	caption_label.add_theme_color_override("font_color", BUTTON_TEXT)
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(caption_label)

# Aspetto del contatore: barra a capsula + coin.png direttamente sovrapposta.
# Tutti i componenti ignorano il mouse: nessuna interazione/click.
func _build_coin_counter(parent: Control) -> void:
	var counter := Control.new()
	counter.name = "CoinsCounter"
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(counter)
	preload("res://scenes/balatro/scripts/safe_edges.gd").attach(counter, true)
	counter.anchor_left = 1.0
	counter.anchor_right = 1.0
	counter.anchor_top = 0.0
	counter.anchor_bottom = 0.0
	counter.offset_left = -COINS_RIGHT_MARGIN - COINS_SIZE.x
	counter.offset_right = -COINS_RIGHT_MARGIN
	counter.offset_top = COINS_TOP_MARGIN
	counter.offset_bottom = COINS_TOP_MARGIN + COINS_SIZE.y

	var bar := Panel.new()
	bar.name = "CoinBar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter.add_child(bar)
	bar.position = Vector2(COINS_ICON_SIZE * 0.45, (COINS_SIZE.y - COINS_BAR_HEIGHT) / 2.0)
	bar.size = Vector2(COINS_SIZE.x - bar.position.x, COINS_BAR_HEIGHT)
	var bar_style := _menu_button_style(BUTTON_PURPLE)
	bar_style.set_corner_radius_all(int(COINS_BAR_HEIGHT / 2.0))
	bar.add_theme_stylebox_override("panel", bar_style)

	# Il numero e' centrato nella parte di barra libera a destra dell'icona.
	coins_label = Label.new()
	coins_label.name = "CoinsAmount"
	coins_label.text = "0"
	coins_label.position = Vector2(COINS_ICON_SIZE + 3.0, 0.0)
	coins_label.size = Vector2(COINS_SIZE.x - COINS_ICON_SIZE - 6.0, COINS_BAR_HEIGHT)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coins_label.add_theme_font_override("font", KIDS_FONT)
	coins_label.add_theme_font_size_override("font_size", COINS_FONT_SIZE)
	coins_label.add_theme_color_override("font_color", BUTTON_TEXT)
	bar.add_child(coins_label)
	# Le coordinate del Label sono locali al Panel: sottrai l'offset della barra.
	coins_label.position.x -= bar.position.x

	# L'immagine della moneta e' direttamente sovrapposta al lato sinistro
	# della barra: nessun pulsante o medaglione circolare dietro.
	if ResourceLoader.exists(COINS_ICON_PATH):
		var coin_icon := TextureRect.new()
		coin_icon.name = "CoinIcon"
		coin_icon.texture = load(COINS_ICON_PATH) as Texture2D
		coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		counter.add_child(coin_icon)
		coin_icon.position = Vector2(20.0, (COINS_SIZE.y - COINS_ICON_SIZE) / 2.0)
		coin_icon.size = Vector2.ONE * COINS_ICON_SIZE
	else:
		push_warning("Immagine delle monete non trovata: " + COINS_ICON_PATH)

func _refresh_account_coins() -> void:
	var cloud := get_node("/root/AccountProfile")
	var account := get_node("/root/AccountSession")
	# Nessun saldo puo' passare da un'identita' all'altra.
	var matching: bool = not str(account.user_id).is_empty() and str(cloud.profile.get("id", "")) == str(account.user_id)
	set_coins_amount(int(cloud.profile.get("credits", 0)) if matching else 0)


# Aggiorna solo la visualizzazione: i crediti vengono letti, mai scritti dal client.
func set_coins_amount(amount: int) -> void:
	if is_instance_valid(coins_label):
		coins_label.text = str(maxi(amount, 0))
	if is_instance_valid(shop_page) and is_instance_valid(shop_page.coins_amount):
		shop_page.coins_amount.text = str(maxi(amount, 0))
	if is_instance_valid(personalization_page):
		personalization_page.set_coins_amount(maxi(amount, 0))


func _menu_button_style(
	color: Color,
	border_color: Color = Color.TRANSPARENT,
	border_width: int = 0,
	button_height: float = 0.0
) -> StyleBoxFlat:
	return LexispellStyle.button_style(color, border_color, border_width, button_height)

func _has_special(value: String) -> bool:
	for character in "+-/éÉ?'−·…":
		if value.contains(character):
			return true
	return false

func _refresh_default_name() -> void:
	if not is_instance_valid(name_input):
		return
	var cloud := get_node("/root/AccountProfile")
	var default_name: String = cloud.account_display_name()
	# Solo un valore predefinito: non rinomina chi ha scelto un nome lobby proprio.
	var net := get_node("/root/NetworkSession")
	if net.room_code.is_empty() and (name_input.text.strip_edges().is_empty() or name_input.text == account_default_name):
		name_input.text = default_name
		_refresh_single_profile()
	account_default_name = default_name

func chosen_name() -> String:
	# Do not rewrite a focused LineEdit on every mobile input event: it
	# reopens the native keyboard and resets composition/caret positioning.
	var value := name_input.text.strip_edges().to_upper()
	return "Giocatore" if value.is_empty() else value

func show_setup() -> void:
	match_options.reset_singleplayer()
	profile_panel.reparent(menu_content, false)
	menu_content.move_child(profile_panel, 0)
	profile_panel.position = Vector2(60, 140)
	title.hide()
	friends_subtitle.hide()
	if solo_transition and solo_transition.is_valid():
		solo_transition.kill()
	friends_subtitle.text = "SOLITARIA"
	friends_subtitle.set_animated(true)
	friends_subtitle.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	friends_subtitle.position = SOLO_SUBTITLE_POSITION
	friends_subtitle.size.x = TITLE_WIDTH
	title.position = SOLO_TITLE_POSITION
	single_name_input.text = name_input.text
	_switch_page(setup_page)
	_animate_mode_heading("SOLITARIA")
	_home_pop_buttons(solo_buttons)
	match_options.pivot_offset = match_options.size / 2.0
	match_options.scale = Vector2.ZERO
	home_intro.tween_property(match_options, "scale", Vector2.ONE, HOME_INTRO_DURATION).from(Vector2.ZERO).set_delay(HOME_INTRO_DELAY).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_mode_heading(subtitle_text: String) -> void:
	if solo_transition and solo_transition.is_valid():
		solo_transition.kill()
	title.position = SOLO_TITLE_POSITION
	friends_subtitle.position = SOLO_SUBTITLE_POSITION
	if subtitle_text == "WITH YOUR FRIENDS":
		title.position += MULTIPLAYER_CONTENT_OFFSET
		friends_subtitle.position += MULTIPLAYER_CONTENT_OFFSET
	friends_subtitle.text = subtitle_text
	friends_subtitle.size.x = TITLE_WIDTH
	friends_subtitle.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	friends_subtitle.set_animated(true)
	solo_transition = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if subtitle_text == "WITH YOUR FRIENDS":
		second_character.position = SECOND_CHARACTER_POSITION + Vector2(1920, 0)
		second_character.show()
		solo_transition.tween_property(second_character, "position", SECOND_CHARACTER_POSITION, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	else:
		second_character.hide()
	if is_instance_valid(home_character):
		var character_target := MULTI_CHARACTER_POSITION if subtitle_text == "WITH YOUR FRIENDS" else SOLO_CHARACTER_POSITION
		solo_transition.tween_property(home_character, "position", character_target, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	for heading in [title, friends_subtitle]:
		heading.pivot_offset = heading.size / 2.0
		heading.scale = Vector2.ZERO
		heading.show()
		solo_transition.tween_property(heading, "scale", Vector2.ONE, HOME_INTRO_DURATION).from(Vector2.ZERO).set_delay(0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func show_home() -> void:
	if returning_home:
		return
	returning_home = true
	var previous := active_page
	if solo_transition and solo_transition.is_valid():
		solo_transition.kill()
	if is_instance_valid(previous) and previous != home_page:
		for item in [previous, title, friends_subtitle]:
			item.hide()
		previous.scale = Vector2.ONE
	var was_customizing := customization_character_ready
	var character_position := HOME_CHARACTER_POSITION
	if was_customizing and is_instance_valid(shop_character):
		character_position = shop_character.position
	elif is_instance_valid(home_character):
		character_position = home_character.position
	var second_was_visible := second_character.visible
	_show_menu_title(true)
	_switch_page(home_page, true)
	const CHARACTER_TRANSITION_DURATION := 0.42
	var entrance := create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if is_instance_valid(home_character):
		# Ripercorriamo al contrario le posizioni finali della transizione verso lo shop.
		home_character.position = SOLO_CHARACTER_POSITION if was_customizing else character_position
		home_character.modulate.a = 0.0 if was_customizing else 1.0
		entrance.tween_property(home_character, "position", HOME_CHARACTER_POSITION, CHARACTER_TRANSITION_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		if was_customizing:
			entrance.tween_property(home_character, "modulate:a", 1.0, CHARACTER_TRANSITION_DURATION).from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if was_customizing and is_instance_valid(shop_character):
		shop_character.position = SOLO_CHARACTER_POSITION + Vector2(-80, -30)
		shop_character.modulate.a = 1.0
		shop_character.show()
		entrance.tween_property(shop_character, "position", HOME_CHARACTER_POSITION, CHARACTER_TRANSITION_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		entrance.tween_property(shop_character, "modulate:a", 0.0, CHARACTER_TRANSITION_DURATION).from(1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		entrance.tween_callback(shop_character.hide).set_delay(CHARACTER_TRANSITION_DURATION)
	if second_was_visible:
		second_character.show()
		entrance.tween_property(second_character, "position:x", 1920.0, CHARACTER_TRANSITION_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		entrance.tween_callback(second_character.hide).set_delay(CHARACTER_TRANSITION_DURATION)
	for heading in [title, friends_subtitle]:
		heading.scale = Vector2.ZERO
		entrance.tween_property(heading, "scale", Vector2.ONE, HOME_INTRO_DURATION).from(Vector2.ZERO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await entrance.finished
	customization_character_ready = false
	returning_home = false

func _enter_customization_character() -> void:
	if customization_character_ready:
		if is_instance_valid(shop_character):
			shop_character.show()
		if is_instance_valid(personalization_page):
			personalization_page.play_intro()
		return
	if not is_instance_valid(home_character) or not is_instance_valid(shop_character):
		return
	if solo_transition and solo_transition.is_valid():
		solo_transition.kill()
	var start_position := home_character.position
	shop_character.position = start_position
	shop_character.modulate.a = 0.0
	shop_character.show()
	home_character.show()
	home_character.modulate.a = 1.0
	const CHARACTER_TRANSITION_DURATION := 0.42
	var tween := create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	solo_transition = tween
	tween.tween_property(home_character, "position", SOLO_CHARACTER_POSITION, CHARACTER_TRANSITION_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shop_character, "position", SOLO_CHARACTER_POSITION + Vector2(-80, -30), CHARACTER_TRANSITION_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(home_character, "modulate:a", 0.0, CHARACTER_TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shop_character, "modulate:a", 1.0, CHARACTER_TRANSITION_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		if active_page == personalization_page:
			home_character.hide()
			customization_character_ready = true
			personalization_page.play_intro()
	)

func _start() -> void:
	_lock_landscape_web()
	start_requested.emit(chosen_name(), int(bot_slider.value) + 1)
