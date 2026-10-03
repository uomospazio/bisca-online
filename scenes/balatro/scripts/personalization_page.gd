extends Control

const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const SHOP_BUTTON_TEXTURE = preload("res://scenes/balatro/trick_asset/ui_bisca/tastoShop.png")
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const GameAudio = preload("res://scenes/balatro/scripts/game_audio.gd")
const ButtonAudio = preload("res://scenes/balatro/scripts/button_audio.gd")

# Layout basato sulla viewport 1920x1080: mazzo a sinistra, slot in colonna alla sua destra.
const DECK_POSITION := Vector2(1550, 600)
const DECK_SCALE := 1.5
const OBJECTS_POSITION := Vector2(1200, 500)
const SHOP_BUTTON_POSITION := Vector2(1050, 95)
const SHOP_BUTTON_SIZE := Vector2(330, 316)
const INTRO_DELAY := 0.08
const INTRO_STAGGER := 0.09
const INTRO_DURATION := 0.38

var menu_owner: Control
var deck_selector: Control
var throw_selector: Control
var coins_amount: Label
var coin_counter: Control
var back_button: Button
var deck_heading: Label
var shop_button: TextureButton
var intro_tween: Tween
var shop_hover_tween: Tween
var intro_scales: Dictionary = {}
var intro_button_states: Array[Dictionary] = []
var intro_started := false

func setup(menu: Control) -> void:
	menu_owner = menu
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	back_button = menu._button(self, "INDIETRO", menu.show_home)
	menu.match_singleplayer_back(back_button)

	coin_counter = menu.home_persistent_ui.get_node("CoinsCounter").duplicate()
	add_child(coin_counter)
	if coin_counter.has_meta("safe_edge"):
		coin_counter.position -= Vector2(coin_counter.get_meta("safe_edge"))
		coin_counter.remove_meta("safe_edge")
	preload("res://scenes/balatro/scripts/safe_edges.gd").attach(coin_counter, true)
	coins_amount = coin_counter.get_node("CoinBar/CoinsAmount")
	coin_counter.scale = Vector2.ONE

	deck_selector = menu.deck_selector
	deck_selector.reparent(self, false)
	deck_selector.position = DECK_POSITION
	deck_selector.scale = Vector2.ONE * DECK_SCALE
	deck_selector.show()
	deck_selector.reset_preview()

	throw_selector = preload("res://scenes/balatro/scripts/shop_throw_selector.gd").new()
	throw_selector.vertical_layout = true
	add_child(throw_selector)
	throw_selector.position = OBJECTS_POSITION
	throw_selector.setup(menu)

	shop_button = TextureButton.new()
	shop_button.name = "OpenShop"
	shop_button.texture_normal = SHOP_BUTTON_TEXTURE
	shop_button.ignore_texture_size = true
	shop_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	shop_button.position = SHOP_BUTTON_POSITION
	shop_button.size = SHOP_BUTTON_SIZE
	shop_button.tooltip_text = "Apri lo shop"
	shop_button.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_button.pivot_offset = shop_button.size / 2.0
	shop_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	shop_button.mouse_entered.connect(func(): _animate_shop_hover(true))
	shop_button.mouse_exited.connect(func(): _animate_shop_hover(false))
	shop_button.focus_entered.connect(func(): _animate_shop_hover(true))
	shop_button.focus_exited.connect(func(): _animate_shop_hover(false))
	shop_button.pressed.connect(func():
		ButtonAudio.play(shop_button, ButtonAudio.CLICK)
		menu._show_shop()
	)
	add_child(shop_button)

	get_node("/root/AccountProfile").changed.connect(_refresh_coins)
	get_node("/root/ShopManager").changed.connect(_refresh_objects)
	visibility_changed.connect(_on_visibility_changed)
	_refresh_coins()
	_refresh_objects()

func open() -> void:
	_stop_intro()
	if deck_selector.get_parent() != self:
		deck_selector.reparent(self, false)
	deck_selector.position = DECK_POSITION
	deck_selector.scale = Vector2.ONE * DECK_SCALE
	deck_selector.show()
	deck_selector.reset_preview()
	throw_selector.refresh()
	_refresh_coins()
	_refresh_objects()
	_prepare_intro()

func play_intro() -> void:
	if intro_started or not is_visible_in_tree():
		return
	intro_started = true
	var controls: Array[Control] = [back_button, coin_counter, deck_heading, deck_selector, throw_selector, shop_button]
	var tween := create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro_tween = tween
	for index in controls.size():
		var control: Control = controls[index]
		if not is_instance_valid(control):
			continue
		var final_scale: Vector2 = intro_scales.get(control.get_instance_id(), Vector2.ONE)
		var delay := INTRO_DELAY + index * INTRO_STAGGER
		tween.tween_property(control, "scale", final_scale, INTRO_DURATION).from(Vector2.ZERO).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(control, "modulate:a", 1.0, INTRO_DURATION).from(0.0).set_delay(delay)
	tween.chain().tween_callback(_restore_button_states)

func _prepare_intro() -> void:
	intro_started = false
	var controls: Array[Control] = [back_button, coin_counter, deck_heading, deck_selector, throw_selector, shop_button]
	intro_scales.clear()
	for control in controls:
		if not is_instance_valid(control):
			continue
		intro_scales[control.get_instance_id()] = control.scale
		control.pivot_offset = control.size / 2.0
		control.scale = Vector2.ZERO
		control.modulate.a = 0.0
		_disable_buttons(control)

func _disable_buttons(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		intro_button_states.append({
			"button": button,
			"mouse_filter": button.mouse_filter,
			"focus_mode": button.focus_mode,
		})
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_buttons(child)

func _restore_button_states() -> void:
	for state in intro_button_states:
		var button: BaseButton = state.get("button")
		if is_instance_valid(button):
			button.mouse_filter = int(state.get("mouse_filter", Control.MOUSE_FILTER_STOP))
			button.focus_mode = int(state.get("focus_mode", Control.FOCUS_ALL))
	intro_button_states.clear()

func _stop_intro() -> void:
	if intro_tween and intro_tween.is_valid():
		intro_tween.kill()
	_restore_button_states()
	if shop_hover_tween and shop_hover_tween.is_valid():
		shop_hover_tween.kill()
	if is_instance_valid(shop_button):
		shop_button.scale = Vector2.ONE
		shop_button.rotation_degrees = 0.0

func _animate_shop_hover(hovered: bool) -> void:
	if not is_instance_valid(shop_button):
		return
	if shop_hover_tween and shop_hover_tween.is_valid():
		shop_hover_tween.kill()
	shop_button.pivot_offset = shop_button.size / 2.0
	shop_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if hovered:
		GameAudio.play(self, GameAudio.NOTICE, -4.0)
		var ratio := clampf(128.0 / maxf(shop_button.size.x, 1.0), 0.5, 1.0)
		shop_hover_tween.tween_property(shop_button, "scale", Vector2.ONE * (1.0 + 0.2 * ratio), 0.2)
		shop_hover_tween.parallel().tween_property(shop_button, "rotation_degrees", 5.0 * ratio * [-1.0, 1.0].pick_random(), 0.1)
		shop_hover_tween.tween_property(shop_button, "rotation_degrees", 0.0, 0.1)
	else:
		shop_hover_tween.tween_property(shop_button, "scale", Vector2.ONE, 0.25)
		shop_hover_tween.parallel().tween_property(shop_button, "rotation_degrees", 0.0, 0.1)

func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_stop_intro()

func _refresh_objects() -> void:
	if is_instance_valid(throw_selector):
		throw_selector.refresh()

func _refresh_coins() -> void:
	if not is_instance_valid(coins_amount):
		return
	var account := get_node("/root/AccountSession")
	var profile := get_node("/root/AccountProfile")
	var belongs_to_user := not str(account.user_id).is_empty() and str(profile.profile.get("id", "")) == str(account.user_id)
	coins_amount.text = str(int(profile.profile.get("credits", 0)) if belongs_to_user else 0)

func set_coins_amount(amount: int) -> void:
	if is_instance_valid(coins_amount):
		coins_amount.text = str(maxi(amount, 0))

func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Style.TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
