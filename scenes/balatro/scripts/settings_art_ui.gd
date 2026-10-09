extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"

const SETTINGS_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/settingsUI/"
const ROOM_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/InLobbyUI/"
const DESIGN_SIZE := Vector2(1842, 784)
var owner_page
var menu
var panel: TextureRect
var username: Label
var public_id: Label
var edit: Button
var privacy: Button
var language_button: Button
var language_open: TextureRect
var language_choice: Button
var toggle_buttons: Dictionary = {}
var volume_sliders: Dictionary = {}
var volume_numbers: Dictionary = {}
var pop_tween: Tween
var provider_overlays: Dictionary = {}

func setup_settings(host_page: Control, host_menu: Control) -> void:
	owner_page = host_page
	menu = host_menu
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	set_meta("cartoon_style_children_excluded", true)
	font = owner_page.FONT.duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	font.msdf_size = 64
	font.msdf_pixel_range = 8
	composition = Control.new()
	add_child(composition)
	composition.size = DESIGN_SIZE
	composition.mouse_filter = MOUSE_FILTER_IGNORE
	panel = _image(composition, SETTINGS_ART + "settingsPanel.png", Rect2(Vector2.ZERO, DESIGN_SIZE))
	username = _label(panel, "", Rect2(235, 272, 335, 46), 32, Color("ffda7c"))
	username.clip_text = true
	username.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	public_id = _label(panel, "", Rect2(216, 319, 352, 40), 29)
	edit = _button(panel, SETTINGS_ART + "modificaUsername.png", Rect2(584, 259, 308, 104), func(): _account("username"))
	for index in 3:
		var provider: String = ["apple", "google", "email"][index]
		var rect := Rect2(40 + index * 294, 388, 276, 84)
		provider_overlays[provider] = _image(panel, SETTINGS_ART + provider + "Connesso.png", rect)
		_hotspot(panel, rect, _open_provider.bind(provider)).tooltip_text = "Account " + provider.capitalize()
	_hotspot(panel, Rect2(40, 480, 866, 80), func(): _account("new_guest")).tooltip_text = "Continua con un nuovo ospite"
	privacy = _hotspot(panel, Rect2(969, 286, 815, 76), func(): owner_page.privacy_button.pressed.emit())
	_make_toggle("show_thrown_objects", Vector2(1696, 150))
	_make_toggle("push_notifications", Vector2(1696, 218))
	_make_toggle("microphone_enabled", Vector2(1696, 653))
	_make_slider("main", 510)
	_make_slider("effects", 578)
	language_button = _button(panel, SETTINGS_ART + "italiano.png", Rect2(530, 614, 348, 76), func():
		language_open.visible = not language_open.visible
	)
	language_button.tooltip_text = "Lingua / Language"
	language_open = _image(panel, SETTINGS_ART + "italianoOpen.png", Rect2(530, 614, 348, 170))
	language_open.z_index = 5
	_hotspot(language_open, Rect2(0, 0, 348, 76), func(): language_open.hide())
	language_choice = _hotspot(language_open, Rect2(10, 88, 328, 72), func():
		owner_page.settings.set_value("language", "it" if owner_page.settings.values.language == "en" else "en")
		language_open.hide()
	)
	language_open.hide()
	back = _button(self, ROOM_ART + "tastoIndietro.png", Rect2(40, 40, 108, 98), menu.show_home)
	back.tooltip_text = "Indietro"
	owner_page.settings.changed.connect(sync)
	get_node("/root/AccountProfile").changed.connect(sync)
	get_node("/root/AccountSession").changed.connect(sync)
	get_node("/root/RewardedAds").changed.connect(sync)
	get_node("/root/PushNotifications").registration_changed.connect(func(_registered, _message): sync())
	get_viewport().size_changed.connect(_fit)
	owner_page.visibility_changed.connect(func():
		if owner_page.is_visible_in_tree(): open()
		elif pop_tween and pop_tween.is_valid(): pop_tween.kill()
	)
	sync()
	open.call_deferred()

func _account(action: String) -> void:
	var account_panel := preload("res://scenes/balatro/scripts/account_panel.gd").new()
	owner_page.add_child(account_panel)
	account_panel.setup(menu, action)

func _open_provider(provider: String) -> void:
	var session := get_node("/root/AccountSession")
	if session.provider_accounts.has(provider):
		_account("connected_" + provider)
	else:
		_account("login" if provider == "email" else "signin_" + provider)

func _hotspot(parent: Node, rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	parent.add_child(button)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	button.pressed.connect(action)
	RoundedSquareButton.ButtonAudio.attach(button)
	return button

func _skin(button: Button, path: String) -> void:
	preload("res://scenes/balatro/scripts/menu_button_hover.gd").attach(button)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = load(path)
		style.modulate_color = Color(0.65, 0.65, 0.65) if button.disabled else Color.WHITE
		if state == "pressed": style.modulate_color = Color(0.8, 0.8, 0.8)
		button.add_theme_stylebox_override(state, style)

func _make_toggle(key: String, at: Vector2) -> void:
	var button := _button(panel, ROOM_ART + "toggleOn.png", Rect2(at, Vector2(72, 41.5)), func():
		var model: CheckButton = owner_page.toggles[key]
		model.button_pressed = not model.button_pressed
	)
	toggle_buttons[key] = button

func _make_slider(key: String, y: float) -> void:
	var slider := HSlider.new()
	panel.add_child(slider)
	slider.position = Vector2(1328, y)
	slider.size = Vector2(326, 56)
	slider.max_value = 100
	slider.step = 1
	for state in ["slider", "grabber_area", "grabber_area_highlight"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("26d33a") if state != "slider" else Color("343047")
		style.set_corner_radius_all(10)
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		slider.add_theme_stylebox_override(state, style)
	slider.add_theme_icon_override("grabber", preload("res://scenes/balatro/visuals/settings_knob.svg"))
	slider.add_theme_icon_override("grabber_highlight", preload("res://scenes/balatro/visuals/settings_knob_hover.svg"))
	slider.value_changed.connect(func(value): owner_page.sliders[key].value = value)
	slider.drag_ended.connect(func(changed): owner_page.sliders[key].drag_ended.emit(changed))
	volume_sliders[key] = slider
	var number := _label(panel, "", Rect2(1692, y, 84, 56), 27)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_numbers[key] = number

func sync() -> void:
	var session := get_node("/root/AccountSession")
	for provider in provider_overlays:
		provider_overlays[provider].visible = session.provider_accounts.has(provider)
	var profile: Dictionary = get_node("/root/AccountProfile").profile
	var name_value = profile.get("username")
	username.text = str(name_value) if name_value != null and not str(name_value).is_empty() else "NON SCELTO"
	username.tooltip_text = username.text
	var id_value = profile.get("public_id")
	public_id.text = "#" + str(id_value) if id_value != null else "IN ATTESA"
	for key in toggle_buttons:
		var model: CheckButton = owner_page.toggles[key]
		var button: Button = toggle_buttons[key]
		button.disabled = model.disabled
		button.tooltip_text = model.tooltip_text
		_skin(button, ROOM_ART + ("toggleOn.png" if model.button_pressed else "toggleOff.png"))
	for key in volume_sliders:
		volume_sliders[key].set_value_no_signal(owner_page.settings.values[key])
		volume_numbers[key].text = str(int(owner_page.settings.values[key]))
	privacy.disabled = owner_page.privacy_button.disabled
	privacy.tooltip_text = owner_page.privacy_status.text
	var english: bool = owner_page.settings.values.language == "en"
	_skin(language_button, SETTINGS_ART + ("english.png" if english else "italiano.png"))
	language_open.texture = load(SETTINGS_ART + ("englishOpen.png" if english else "italianoOpen.png"))

func open() -> void:
	if not owner_page.is_visible_in_tree(): return
	if pop_tween and pop_tween.is_valid(): pop_tween.kill()
	language_open.hide()
	sync()
	_fit()
	composition.pivot_offset = DESIGN_SIZE / 2
	# Animate a child wrapper's opacity and scale through the content root;
	# keep responsive fitting separate from the pop multiplier.
	var target_scale := composition.scale
	composition.scale = Vector2.ZERO
	back.scale = Vector2.ZERO
	pop_tween = create_tween().set_parallel(true)
	pop_tween.tween_property(composition, "scale", target_scale, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(back, "scale", Vector2.ONE, 0.38).set_delay(0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _layout(bounds: Rect2) -> void:
	var factor := maxf(0.01, minf(bounds.size.x / DESIGN_SIZE.x, bounds.size.y / DESIGN_SIZE.y))
	composition.pivot_offset = DESIGN_SIZE / 2
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center() - DESIGN_SIZE / 2
	back.position = bounds.position
	var center := get_global_transform_with_canvas().affine_inverse() * (get_viewport_rect().size / 2)
	back.size = Vector2(108, 98) * preload("res://scenes/balatro/scripts/in_lobby_ui.gd").layout_scale(bounds, center)
	back.pivot_offset = back.size / 2
