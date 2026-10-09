extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"

const ART_HOME := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/"
const DESIGN := Vector2(1840, 840)
const TITLE_RECT := Rect2(-40, -30, 1034, 542)
const SINGLEPLAYER_RECT := Rect2(211, 425, 554, 140)
const MULTIPLAYER_RECT := Rect2(211, 580, 554, 140)
const SHOW_PURPLE_BACKGROUND := true # false per tornare allo sfondo precedente.
var owner_menu: Control
var amount: Label
var blocks: Array[Control] = []
var pop_tween: Tween

func setup_home(host: Control) -> void:
	owner_menu = host
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	set_meta("cartoon_style_children_excluded", true)
	font = host.KIDS_FONT.duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	composition = Control.new()
	add_child(composition)
	composition.mouse_filter = MOUSE_FILTER_IGNORE
	composition.size = DESIGN
	var logo := _image(composition, ART_HOME + "titoloHome.png", TITLE_RECT)
	var single := _button(composition, ART_HOME + "tastoSingleplayer.png", SINGLEPLAYER_RECT, host.show_setup)
	var multi := _button(composition, ART_HOME + "tastoMultiplayer.png", MULTIPLAYER_RECT, host._show_network)
	host.home_character.reparent(composition, false)
	host.home_character.position = host.HOME_CHARACTER_POSITION
	host.home_character.size = host.HOME_CHARACTER_SIZE
	var counter := _image(composition, ART_HOME + "contatoreMonete.png", Rect2(1540, 0, 300, 110))
	amount = _label(counter, host.coins_label.text, Rect2(112, 18, 180, 72), 40)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var custom := _button(composition, ART_HOME + "buttonPersonalizzazione.png", Rect2(1720, 130, 116, 116), host._show_personalization)
	var friends := _button(composition, ART_HOME + "buttonAmici.png", Rect2(1720, 278, 116, 116), host._show_friends)
	var settings := _button(composition, ART_HOME + "buttonSettings.png", Rect2(1720, 426, 116, 116), host._show_settings)
	host.friends_dot.reparent(friends, false)
	host.friends_dot.position = Vector2(94, 0)
	host.username_dot.reparent(settings, false)
	host.username_dot.position = Vector2(94, 0)
	var shop := _button(composition, "res://scenes/balatro/trick_asset/ui_bisca/tastoShop.png", Rect2(1600, 580, 240, 230), host._show_shop)
	blocks = [logo, single, multi, counter, custom, friends, settings, shop]
	get_viewport().size_changed.connect(_fit)
	_fit()

func open() -> void:
	owner_menu.title.hide()
	owner_menu.friends_subtitle.hide()
	amount.text = owner_menu.coins_label.text
	_fit()
	if pop_tween and pop_tween.is_valid(): pop_tween.kill()
	pop_tween = create_tween().set_parallel(true)
	for index in blocks.size():
		var block := blocks[index]
		block.pivot_offset = block.size / 2
		block.scale = Vector2.ZERO
		pop_tween.tween_property(block, "scale", Vector2.ONE, 0.38).set_delay(index * 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _layout(bounds: Rect2) -> void:
	var factor := minf(bounds.size.x / DESIGN.x, bounds.size.y / DESIGN.y)
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center() - DESIGN * factor / 2
