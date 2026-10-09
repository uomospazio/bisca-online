extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"

const SOLO_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/solitariaUI/"
const ROOM_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/InLobbyUI/"
const SOLO_SIZE := Vector2(1658, 796)
const SETTINGS_SIZE := Vector2(754, 754.0 * 704.0 / 1536.0)
var back_anchor: Control
var menu
var hero: TextureRect
var logo: TextureRect
var settings: TextureRect
var play: Button
const HERO_RECT := Rect2(20, 20, 720, 1070.88)

func setup(owner_menu: Control) -> void:
	menu = owner_menu
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	set_meta("cartoon_style_children_excluded", true)
	font = menu.KIDS_FONT.duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	font.msdf_size = 64
	composition = Control.new()
	add_child(composition)
	composition.size = SOLO_SIZE
	composition.mouse_filter = MOUSE_FILTER_IGNORE
	hero = _image(composition, "res://scenes/balatro/resources/personaggio_menu.png", HERO_RECT)
	logo = _image(composition, SOLO_ART + "logoSolitaria.png", Rect2(830, 0, 694, 278))
	settings = _image(composition, SOLO_ART + "impostazioniSolitaria.png", Rect2(Vector2(800, 290), SETTINGS_SIZE))
	for index in 3:
		var model: Range = [menu.match_options.lives, menu.match_options.rounds, menu.match_options.bot_count][index]
		var center_y := (79.0 + index * 98.0) * 754.0 / 768.0
		var number := _label(settings, str(int(model.value)), Rect2(549, center_y - 29, 108, 56), 38)
		var padding := StyleBoxEmpty.new()
		padding.content_margin_top = 6
		number.add_theme_stylebox_override("normal", padding)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var minus := _option_button(settings, "tasto-.png", Vector2(500, center_y - 34), func(): model.value -= 1)
		var plus := _option_button(settings, "tasto+.png", Vector2(638, center_y - 34), func(): model.value += 1)
		var refresh := func(_value = 0):
			number.text = str(int(model.value))
			minus.disabled = model.value <= model.min_value
			plus.disabled = model.value >= model.max_value
			minus.modulate.a = 0.45 if minus.disabled else 1.0
			plus.modulate.a = 0.45 if plus.disabled else 1.0
		model.value_changed.connect(refresh)
		refresh.call()
	play = _button(composition, SOLO_ART + "gioca.png", Rect2(960, 666, 442, 104), menu._start)
	back_anchor = Control.new()
	add_child(back_anchor)
	back_anchor.mouse_filter = MOUSE_FILTER_IGNORE
	back = _button(back_anchor, ROOM_ART + "tastoIndietro.png", Rect2(0, 0, 108, 98), menu.show_home)
	back.tooltip_text = "Indietro"
	get_viewport().size_changed.connect(_fit)
	_fit.call_deferred()

func _layout(bounds: Rect2) -> void:
	var factor := maxf(0.01, minf(bounds.size.x / SOLO_SIZE.x, bounds.size.y / SOLO_SIZE.y))
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center() - SOLO_SIZE * factor * 0.5
	back_anchor.position = bounds.position
	back_anchor.scale = Vector2.ONE * factor

func _option_button(parent: Control, filename: String, at: Vector2, action: Callable) -> Button:
	# Same 64x64 hit area and 64x70 artwork as the multiplayer room.
	var button := Button.new()
	parent.add_child(button)
	button.position = at
	button.size = Vector2(64, 64)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.size = Vector2(64, 64)
	var artwork := _image(button, ROOM_ART + filename, Rect2(0, 0, 64, 70))
	button.mouse_entered.connect(func(): artwork.modulate = Color(1.15, 1.15, 1.15))
	button.mouse_exited.connect(func(): artwork.modulate = Color.WHITE)
	button.pressed.connect(action)
	RoundedSquareButton.ButtonAudio.attach(button)
	preload("res://scenes/balatro/scripts/menu_button_hover.gd").attach(button)
	return button

func pop() -> void:
	if intro and intro.is_valid(): intro.kill()
	if character_intro and character_intro.is_valid(): character_intro.kill()
	_fit()
	var source: TextureRect = menu.home_character
	var texture_size := source.texture.get_size()
	var fitted := texture_size * minf(source.size.x / texture_size.x, source.size.y / texture_size.y)
	var mapping := composition.get_global_transform_with_canvas().affine_inverse() * source.get_global_transform_with_canvas()
	hero.position = mapping * ((source.size - fitted) * 0.5)
	hero.size = (mapping * fitted - mapping * Vector2.ZERO).abs()
	character_intro = create_tween().set_parallel(true)
	character_intro.tween_property(hero, "position", HERO_RECT.position, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	character_intro.tween_property(hero, "size", HERO_RECT.size, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	intro = create_tween().set_parallel(true)
	var groups := [logo, settings, play, back]
	for index in groups.size():
		var block: Control = groups[index]
		block.pivot_offset = block.size / 2
		block.scale = Vector2.ZERO
		intro.tween_property(block, "scale", Vector2.ONE, 0.38).set_delay(0.55 + index * 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
