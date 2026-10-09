extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"

const PERSONAL_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/personalizzazioneUI/"
const SHOP_BUTTON_SIZE := Vector2(330, 316)
const PAGE_SIZE := Vector2(1820, 820)
const PANEL_RECT := Rect2(960, 0, 852, 820)
const HERO_RECT := Rect2(280, 50, 810, 1104)
const PROFILE_POSITION := Vector2(0, 145)
const PROFILE_SCALE := 1.0
var profile_art: TextureRect
var profile_photo: TextureButton
var profile_name: LineEdit
var profile_group: Control
var menu_owner: Control
var panel: TextureRect
var hero: TextureRect
var deck_selector: Control
var throw_selector: Control
var back_button: Button
var intro_tween: Tween
var intro_started := false
var customization_group: Control

func setup(menu: Control) -> void:
	menu_owner = menu
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	set_meta("cartoon_style_children_excluded", true)
	composition = Control.new()
	add_child(composition)
	composition.size = PAGE_SIZE
	composition.mouse_filter = MOUSE_FILTER_IGNORE
	customization_group = Control.new()
	composition.add_child(customization_group)
	customization_group.size = PAGE_SIZE
	customization_group.mouse_filter = MOUSE_FILTER_IGNORE
	customization_group.pivot_offset = PANEL_RECT.get_center()
	panel = _image(customization_group, PERSONAL_ART + "panelPersonalizzazione.png", PANEL_RECT)
	_build_profile()
	hero = _image(composition, menu.SHOP_CHARACTER_PATH, HERO_RECT)
	deck_selector = menu.deck_selector
	throw_selector = preload("res://scenes/balatro/scripts/shop_throw_selector.gd").new()
	customization_group.add_child(throw_selector)
	throw_selector.artwork_skin = true
	throw_selector.setup(menu)
	throw_selector.apply_personalization_skin(load(PERSONAL_ART + "buttonOggetto.png"))
	back_button = _button(self, UI + "pngUI/InLobbyUI/tastoIndietro.png", Rect2(40, 40, 108, 98), menu.show_home)
	back_button.tooltip_text = "Indietro"
	get_node("/root/ShopManager").changed.connect(throw_selector.refresh)
	get_viewport().size_changed.connect(_fit)
	visibility_changed.connect(func():
		if not is_visible_in_tree():
			if intro_tween and intro_tween.is_valid(): intro_tween.kill()
			if character_intro and character_intro.is_valid(): character_intro.kill()
			for control in _intro_contents():
				control.scale = Vector2.ONE
	)

func open() -> void:
	_sync_profile()
	if intro_tween and intro_tween.is_valid(): intro_tween.kill()
	if character_intro and character_intro.is_valid(): character_intro.kill()
	if deck_selector.get_parent() != customization_group:
		deck_selector.reparent(customization_group, false)
	deck_selector.show()
	deck_selector.size = Vector2(572, 272)
	deck_selector.position = PANEL_RECT.position + Vector2(172, 232)
	deck_selector.scale = Vector2.ONE
	deck_selector.modulate = Color.WHITE
	deck_selector.front_preview.position = Vector2.ZERO
	deck_selector.back_preview.position = Vector2(354, 0)
	deck_selector.reset_preview()
	throw_selector.position = PANEL_RECT.position + Vector2(156, 638)
	throw_selector.refresh()
	throw_selector.scale = Vector2.ONE
	if deck_selector.front_tween and deck_selector.front_tween.is_valid(): deck_selector.front_tween.kill()
	if deck_selector.back_tween and deck_selector.back_tween.is_valid(): deck_selector.back_tween.kill()
	_fit()
	for block in [profile_art, back_button]:
		block.pivot_offset = block.size / 2
		block.scale = Vector2.ZERO
	panel.scale = Vector2.ONE
	for block in _intro_contents(): block.scale = Vector2.ONE
	customization_group.scale = Vector2.ZERO
	intro_started = false
	hero.size = HERO_RECT.size
	hero.position = HERO_RECT.position
	hero.modulate.a = 1.0
	hero.hide()
	hero.pivot_offset = hero.size / 2
	hero.scale = Vector2.ZERO
	menu_owner.home_character.hide()
	menu_owner.shop_character.hide()
	play_intro()

func _intro_contents() -> Array:
	return [deck_selector.front_preview, deck_selector.back_preview] + throw_selector.buttons

func hero_rect_in(target: Control) -> Rect2:
	var mapping := target.get_global_transform_with_canvas().affine_inverse() * hero.get_global_transform_with_canvas()
	return Rect2(mapping * Vector2.ZERO, (mapping * hero.size - mapping * Vector2.ZERO).abs())

func play_intro() -> void:
	if intro_started or not is_visible_in_tree(): return
	intro_started = true
	intro_tween = create_tween().set_parallel(true)
	# Complete the panel pop before revealing interactive contents.
	var blocks := [profile_art, customization_group, back_button]
	var delays := [0.0, 0.08, 0.0]
	for index in blocks.size():
		intro_tween.tween_property(blocks[index], "scale", Vector2.ONE, 0.38).set_delay(delays[index]).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro_tween.tween_callback(hero.show).set_delay(0.16)
	intro_tween.tween_property(hero, "scale", Vector2.ONE, 0.38).set_delay(0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _layout(bounds: Rect2) -> void:
	var factor := maxf(0.01, minf(bounds.size.x / PAGE_SIZE.x, bounds.size.y / PAGE_SIZE.y))
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center() - PAGE_SIZE * factor / 2
	back_button.position = bounds.position
	var center := get_global_transform_with_canvas().affine_inverse() * (get_viewport_rect().size / 2)
	back_button.size = Vector2(108, 98) * preload("res://scenes/balatro/scripts/in_lobby_ui.gd").layout_scale(bounds, center)
	back_button.pivot_offset = back_button.size / 2

func set_coins_amount(_amount: int) -> void:
	# No coin counter in this reference.
	pass

func _build_profile() -> void:
	profile_group = Control.new()
	composition.add_child(profile_group)
	profile_group.position = PROFILE_POSITION
	profile_group.scale = Vector2.ONE * PROFILE_SCALE
	profile_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	profile_art = _image(profile_group, PERSONAL_ART + "panelProfilo.png", Rect2(0, 0, 420, 484))
	profile_photo = TextureButton.new()
	profile_art.add_child(profile_photo)
	profile_photo.position = Vector2(99, 43)
	profile_photo.size = Vector2(222, 222)
	profile_photo.ignore_texture_size = true
	profile_photo.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	profile_photo.tooltip_text = "Scegli la foto profilo"
	preload("res://scenes/balatro/scripts/menu_button_hover.gd").attach(profile_photo)
	profile_photo.pressed.connect(func(): menu_owner.profile_picker.open(menu_owner.chosen_name()))
	var camera := _image(profile_photo, UI + "camera.svg", Rect2(77, 77, 68, 68))
	camera.name = "Camera"
	menu_owner.profile_picker.selected.connect(func(_avatar): _sync_profile.call_deferred())
	profile_name = LineEdit.new()
	profile_art.add_child(profile_name)
	profile_name.position = Vector2(40, 352)
	profile_name.size = Vector2(340, 86)
	profile_name.placeholder_text = "COME TI CHIAMI?"
	profile_name.max_length = menu_owner.name_input.max_length
	profile_name.alignment = HORIZONTAL_ALIGNMENT_CENTER
	profile_name.add_theme_font_override("font", menu_owner.KIDS_FONT)
	profile_name.add_theme_font_size_override("font_size", 36)
	for state in ["normal", "focus", "read_only"]:
		profile_name.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	profile_name.text_changed.connect(func(value):
		menu_owner.name_input.text = value
		menu_owner.name_input.text_changed.emit(value)
	)
	profile_name.text_submitted.connect(func(_value): menu_owner._send_profile_name())
	profile_name.focus_exited.connect(menu_owner._send_profile_name)
	menu_owner.name_input.text_changed.connect(func(_value): _sync_profile())
	_sync_profile()

func _sync_profile() -> void:
	profile_photo.texture_normal = menu_owner.profile_texture
	profile_photo.get_node("Camera").visible = menu_owner.profile_texture == null
	if profile_name.text != menu_owner.name_input.text:
		profile_name.text = menu_owner.name_input.text
