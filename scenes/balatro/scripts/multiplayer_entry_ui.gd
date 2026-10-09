extends Control
const ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/multiplayerUI/"
const UI := "res://scenes/balatro/trick_asset/ui_bisca/"
const BLOCK_SIZE := Vector2(1000, 955)
const COMPOSITION_SIZE := Vector2(2250, 1100)
const RIGHT_SCALE := 1.12
const RIGHT_POSITION := Vector2(1130, 15.2)
const CHARACTER_ZOOM := 1.15
var page
var font: FontFile
var composition: Control
var right: Control
var characters: Control
var back: Button
var header: Control
var footer: TextureRect
var intro: Tween
var character_intro: Tween
var character_targets: Dictionary = {}
var character_sizes: Dictionary = {}
const CHARACTER_DURATION := 0.55

func setup(owner_page: Control) -> void:
	page = owner_page
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	set_meta("cartoon_style_children_excluded", true)
	font = page.menu.KIDS_FONT.duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	font.msdf_size = 64
	texture_filter = TEXTURE_FILTER_LINEAR
	composition = Control.new()
	add_child(composition)
	composition.size = COMPOSITION_SIZE
	composition.mouse_filter = MOUSE_FILTER_IGNORE
	characters = Control.new()
	composition.add_child(characters)
	characters.mouse_filter = MOUSE_FILTER_IGNORE
	characters.size = Vector2(1140, 1100)
	# Let the artwork extend to the screen edge, not stop at this layout box.
	characters.clip_contents = false
	_image(characters, "res://scenes/balatro/resources/p2_menu.png", Rect2(540, 315, 580, 580.0 * 3158 / 2048))
	_image(characters, "res://scenes/balatro/resources/personaggio_menu.png", Rect2(-10, 130, 820, 820.0 * 3406 / 2290))
	for character in characters.get_children():
		# Zoom around the top center: heads stay at the same height/location,
		# while the lower body naturally extends below the screen.
		var original_size: Vector2 = character.size
		character.size = original_size * CHARACTER_ZOOM
		character.position.x -= (character.size.x - original_size.x) * 0.5
		character_targets[character] = character.position
		character_sizes[character] = character.size
	right = Control.new()
	composition.add_child(right)
	right.size = BLOCK_SIZE
	right.position = RIGHT_POSITION
	right.scale = Vector2.ONE * RIGHT_SCALE
	right.mouse_filter = MOUSE_FILTER_IGNORE
	page.entry = Control.new()
	right.add_child(page.entry)
	page.entry.size = BLOCK_SIZE
	page.entry.mouse_filter = MOUSE_FILTER_IGNORE
	header = _image(page.entry, ART + "nuovapartitaBanner.png", Rect2(0, 0, 1000, 145))
	var create := _button(header, ART + "creaLobby.png", Rect2(590, 20, 395, 105), page._create_public_lobby)
	page.directory_panel = _image(page.entry, ART + "lobbyDisponibili.png", Rect2(0, 170, 1000, 616))
	var scroll := preload("res://scenes/balatro/scripts/touch_scroll.gd").new()
	page.directory_panel.add_child(scroll)
	scroll.position = Vector2(40, 130)
	scroll.size = Vector2(920, 444)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.directory_rows = VBoxContainer.new()
	scroll.add_child(page.directory_rows)
	page.directory_rows.size_flags_horizontal = SIZE_EXPAND_FILL
	page.directory_rows.add_theme_constant_override("separation", 18)
	footer = _image(page.entry, ART + "codiceBanner.png", Rect2(0, 810, 1000, 145))
	_button(footer, ART + "entraconCodice.png", Rect2(590, 20, 395, 105), func(): page._show_form(false))
	back = _button(self, UI + "pngUI/InLobbyUI/tastoIndietro.png", Rect2(40, 40, 108, 98), page._back)
	back.tooltip_text = "Indietro"
	page.entry_buttons.clear()
	page.entry_buttons.append(create)
	page.entry_buttons.append(back)
	get_viewport().size_changed.connect(_fit)
	_fit.call_deferred()

func attach_form() -> void:
	page.controls.reparent(right, false)
	page.controls.position = Vector2(180, 250)
	page.controls.size = Vector2(640, 400)
	attach_status()

func attach_status() -> void:
	if page.info.get_parent() != right:
		page.info.reparent(right, false)
	page.info.position = Vector2(0, 963)
	page.info.size = Vector2(1000, 65)
	page.info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.info.add_theme_font_override("font", font)
	page.info.add_theme_font_size_override("font_size", 24)

func _image(parent: Node, path: String, rect: Rect2) -> TextureRect:
	var image := TextureRect.new()
	parent.add_child(image)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.texture = load(path)
	image.position = rect.position
	image.size = rect.size
	image.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.mouse_filter = MOUSE_FILTER_IGNORE
	return image

func _label(parent: Node, text: String, rect: Rect2, font_size: int, color := Color("f3effe")) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label

func _button(parent: Node, path: String, rect: Rect2, action: Callable, hover_enabled := true) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.position = rect.position
	button.size = rect.size
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = load(path)
		style.modulate_color = Color(0.8, 0.8, 0.8) if state == "pressed" else Color.WHITE
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(action)
	RoundedSquareButton.ButtonAudio.attach(button)
	if hover_enabled:
		preload("res://scenes/balatro/scripts/menu_button_hover.gd").attach(button)
	return button

func render(entries: Array) -> void:
	for child in page.directory_rows.get_children():
		page.directory_rows.remove_child(child)
		child.queue_free()
	var ordered := entries.duplicate(true)
	ordered.sort_custom(func(a, b): return bool(a.get("rejoin", false)) and not bool(b.get("rejoin", false)))
	if ordered.is_empty():
		var empty := _label(page.directory_rows, "Nessuna lobby disponibile. Crea la tua!", Rect2(), 32)
		empty.custom_minimum_size = Vector2(0, 130)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for item in ordered:
		var card := Control.new()
		page.directory_rows.add_child(card)
		card.custom_minimum_size = Vector2(0, 135)
		card.mouse_filter = MOUSE_FILTER_PASS
		card.set_meta("lobby_id", item.get("id", ""))
		var art := _image(card, ART + "slotLobby.png", Rect2(0, 0, 920, 135))
		art.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		var title := _label(card, str(item.get("name", "Lobby")), Rect2(48, 12, 590, 53), 32)
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title.clip_text = true
		_label(card, "%s/%s giocatori" % [item.get("participants", 0), item.get("capacity", 8)], Rect2(88, 73, 520, 44), 28, Color("b7a4e8"))
		if item.get("private", true) and not item.get("rejoin", false):
			_image(card, UI + "lock.svg", Rect2(642, 48, 32, 36))
		var join := _button(card, ART + ("tastoRientra.png" if item.get("rejoin", false) else "tastoEntra.png"), Rect2(685, 24, 210, 87.5), func(): page._join_directory(item))
		join.tooltip_text = "Rientra nella tua lobby" if item.get("rejoin", false) else ("Inserisci il codice" if item.get("private", true) else "Entra nella lobby")

func _fit() -> void:
	if not is_inside_tree(): return
	var viewport_size := get_viewport_rect().size
	var safe := Rect2(Vector2.ZERO, viewport_size)
	if OS.has_feature("web"):
		var fractions = JSON.parse_string(str(JavaScriptBridge.eval("typeof window.biscaSafeArea === 'function' ? window.biscaSafeArea() : '[0,0,1,1]'", true)))
		if fractions is Array and fractions.size() == 4:
			safe = Rect2(Vector2(float(fractions[0]), float(fractions[1])) * viewport_size, Vector2(float(fractions[2]), float(fractions[3])) * viewport_size)
	elif OS.has_feature("mobile"):
		var window := get_window()
		var physical := Rect2(DisplayServer.get_display_safe_area()).intersection(Rect2(Vector2(window.position), Vector2(window.size)))
		if physical.has_area():
			var ratio := viewport_size / Vector2(window.size)
			safe = Rect2((physical.position - Vector2(window.position)) * ratio, physical.size * ratio)
	var inverse := get_global_transform_with_canvas().affine_inverse()
	var bounds := Rect2(inverse * safe.position, inverse * safe.end - inverse * safe.position).grow(-40)
	_layout(bounds)

func _layout(bounds: Rect2) -> void:
	var factor := maxf(0.01, minf(bounds.size.x / COMPOSITION_SIZE.x, bounds.size.y / COMPOSITION_SIZE.y))
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center() - COMPOSITION_SIZE * factor * 0.5
	if is_instance_valid(page.info):
		var center_in_right := right.get_global_transform_with_canvas().affine_inverse() * (get_viewport_rect().size * 0.5)
		page.info.position.x = center_in_right.x - page.info.size.x * 0.5
	back.position = bounds.position
	# Use the room's responsive size, independently of the wider entry artwork.
	var screen_center := get_global_transform_with_canvas().affine_inverse() * (get_viewport_rect().size * 0.5)
	back.size = Vector2(108, 98) * preload("res://scenes/balatro/scripts/in_lobby_ui.gd").layout_scale(bounds, screen_center)
	back.pivot_offset = back.size * 0.5

func pop() -> void:
	if intro and intro.is_valid(): intro.kill()
	show()
	page.entry.show()
	page.directory_panel.show()
	back.show()
	_fit()
	if character_intro and character_intro.is_valid():
		character_intro.kill()
	character_intro = create_tween().set_parallel(true)
	# The main character moves from its actual HOME position, not a made-up
	# offset inside the left panel. Allow that journey across the whole screen.
	characters.clip_contents = false
	for index in characters.get_child_count():
		var character: Control = characters.get_child(index)
		var target: Vector2 = character_targets[character]
		character.size = character_sizes[character]
		if index == 0:
			character.position = target + Vector2(2160, 0)
		else:
			var source: TextureRect = page.menu.home_character
			var texture_size := source.texture.get_size()
			var fitted_size := texture_size * minf(source.size.x / texture_size.x, source.size.y / texture_size.y)
			var mapping := characters.get_global_transform_with_canvas().affine_inverse() * source.get_global_transform_with_canvas()
			character.position = mapping * ((source.size - fitted_size) * 0.5)
			character.size = (mapping * fitted_size - mapping * Vector2.ZERO).abs()
		character_intro.tween_property(character, "position", target, CHARACTER_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		character_intro.tween_property(character, "size", character_sizes[character], CHARACTER_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	intro = create_tween().set_parallel(true)
	var groups: Array[Control] = [header, page.directory_panel, footer, back]
	for index in groups.size():
		var block := groups[index]
		block.pivot_offset = block.size / 2
		block.scale = Vector2.ZERO
		intro.tween_property(block, "scale", Vector2.ONE, 0.38).set_delay(CHARACTER_DURATION + 0.1 * index).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
