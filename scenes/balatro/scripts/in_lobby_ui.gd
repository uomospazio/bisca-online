extends Control
## Artwork-driven lobby. NetworkLobby keeps ownership of networking and option values.
const ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/InLobbyUI/"
const ICONS := "res://scenes/balatro/trick_asset/ui_bisca/"
const PAGE_SIZE := Vector2(1606, 800)
const CONTENT_RECT := Rect2(212, 0, 1394, 796)
var page
var scalable_font: FontFile
var content: Control
var back_anchor: Control
var blocks: Array[Control] = []
var steppers: Array[Dictionary] = []
var private_toggle: Button
var bots_toggle: Button
var pop_tween: Tween
var copy_tween: Tween

func setup(owner_page: Control) -> void:
	page = owner_page
	# Separate font resource: crisp scaled glyphs without changing other screens.
	scalable_font = page.menu.KIDS_FONT.duplicate() as FontFile
	scalable_font.multichannel_signed_distance_field = true
	scalable_font.msdf_pixel_range = 8
	scalable_font.msdf_size = 64
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	set_meta("cartoon_style_children_excluded", true)
	content = Control.new()
	add_child(content)
	content.size = PAGE_SIZE
	content.mouse_filter = MOUSE_FILTER_IGNORE
	var players := _art(content, "listaPlayer.png", Rect2(212, 0, 632, 796))
	page.players_label = _label(players, Rect2(208, 36, 100, 42), 28)
	page.players_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	page.players_box = VBoxContainer.new()
	players.add_child(page.players_box)
	page.players_box.position = Vector2(30, 84)
	page.players_box.size = Vector2(564, 680)
	page.players_box.add_theme_constant_override("separation", 4)

	var settings := Control.new()
	content.add_child(settings)
	settings.position = Vector2(852, 0)
	settings.size = Vector2(754, 680)
	settings.mouse_filter = MOUSE_FILTER_IGNORE
	var panel := _art(settings, "impostazioniLobby.png", Rect2(0, 64, 754, 616))
	private_toggle = _button(panel, "toggleOff.png", Rect2(566, 131, 72, 41.5), func():
		page.lobby_private.button_pressed = not page.lobby_private.button_pressed
	)
	private_toggle.tooltip_text = "Lobby chiusa: accesso con codice"
	bots_toggle = _button(panel, "toggleOff.png", Rect2(252, 427, 72, 41.5), func():
		page.lobby_options.fill_bots.button_pressed = not page.lobby_options.fill_bots.button_pressed
	)
	bots_toggle.tooltip_text = "Attiva o disattiva i bot"
	_stepper(panel, page.lobby_options.lives, 248, "Vite")
	_stepper(panel, page.lobby_options.rounds, 346, "Carte di partenza")
	_stepper(panel, page.lobby_options.bot_count, 444, "Numero bot")
	_stepper(panel, page.lobby_options.turn_timer, 542, "Tempo per turno")
	page.code_button = _button(settings, "codiceLobby.png", Rect2(160, 0, 428, 148), _copy_code)
	page.code_button.tooltip_text = "Copia codice lobby"
	var center := CenterContainer.new()
	page.code_button.add_child(center)
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	center.mouse_filter = MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 20)
	center.add_child(row)
	page.code_label = _label(row, Rect2(), 56)
	page.code_label.resized.connect(func(): page.code_label.pivot_offset = page.code_label.size / 2)
	page.copy_icon = TextureRect.new()
	row.add_child(page.copy_icon)
	page.copy_icon.texture = load(ICONS + "copy.svg")
	page.copy_icon.custom_minimum_size = Vector2(72, 72)
	page.copy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page.copy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	page.copy_icon.mouse_filter = MOUSE_FILTER_IGNORE
	_button(settings, "aggiungiAmico.png", Rect2(620, 24, 88, 88), page._open_invites).tooltip_text = "Invita amici"
	page.start_button = _button(content, "pronto.png", Rect2(1292, 688, 312, 103), func():
		var people: Array = page.net.latest.get("people", [])
		var own := int(page.net.latest.get("you", -1))
		if own >= 0 and own < people.size():
			page.net.send({"op": "ready", "ready": not bool(people[own].get("ready", false))})
	)
	back_anchor = Control.new()
	add_child(back_anchor)
	back_anchor.mouse_filter = MOUSE_FILTER_IGNORE
	var back := _button(back_anchor, "tastoIndietro.png", Rect2(0, 0, 108, 98), page._back)
	back.tooltip_text = "Indietro"
	blocks = [settings, players, page.start_button, back]
	get_viewport().size_changed.connect(_fit)
	_fit.call_deferred()

func _art(parent: Node, filename: String, rect: Rect2) -> TextureRect:
	var view := TextureRect.new()
	parent.add_child(view)
	view.texture = load(ART + filename)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.position = rect.position
	view.size = rect.size
	view.mouse_filter = MOUSE_FILTER_IGNORE
	view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return view

func _label(parent: Node, rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", scalable_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f3effe"))
	# Optical baseline adjustment, including labels managed by containers.
	var text_padding := StyleBoxEmpty.new()
	text_padding.content_margin_top = 6
	label.add_theme_stylebox_override("normal", text_padding)
	return label

func skin_button(button: Button, filename: String) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = load(ART + filename)
		style.modulate_color = Color(0.65, 0.65, 0.65) if state == "disabled" else (Color(1.12, 1.12, 1.12) if state == "hover" else Color.WHITE)
		if state in ["pressed", "hover_pressed"]:
			style.modulate_color = Color(0.8, 0.8, 0.8)
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _button(parent: Node, filename: String, rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.position = rect.position
	button.size = rect.size
	skin_button(button, filename)
	button.pressed.connect(action)
	RoundedSquareButton.ButtonAudio.attach(button)
	return button

func skin_slot(row: PanelContainer, empty: bool) -> void:
	var style := StyleBoxTexture.new()
	style.texture = load(ART + ("emptySlot.png" if empty else "slotLobby.png"))
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	row.add_theme_stylebox_override("panel", style)

func _stepper(panel: Control, model: Range, y: float, caption: String) -> void:
	var value := _label(panel, Rect2(552, y - 28, 108, 56), 38)
	var buttons: Array[Button] = []
	for direction in [-1, 1]:
		var button := Button.new()
		panel.add_child(button)
		button.position = Vector2(516 if direction == -1 else 686, y - 2) - Vector2(32, 32)
		button.size = Vector2(64, 64)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var artwork := _art(button, "tasto-.png" if direction == -1 else "tasto+.png", Rect2(0, 0, 64, 70))
		button.mouse_entered.connect(func(): artwork.modulate = Color(1.15, 1.15, 1.15))
		button.mouse_exited.connect(func(): artwork.modulate = Color.WHITE)
		button.tooltip_text = ("Diminuisci " if direction == -1 else "Aumenta ") + caption
		button.pressed.connect(func():
			if model.editable:
				model.value += direction
		)
		RoundedSquareButton.ButtonAudio.attach(button)
		buttons.append(button)
	steppers.append({"model": model, "label": value, "minus": buttons[0], "plus": buttons[1]})

func sync_options() -> void:
	skin_button(private_toggle, "toggleOn.png" if page.lobby_private.button_pressed else "toggleOff.png")
	private_toggle.disabled = page.lobby_private.disabled
	skin_button(bots_toggle, "toggleOn.png" if page.lobby_options.fill_bots.button_pressed else "toggleOff.png")
	bots_toggle.disabled = page.lobby_options.fill_bots.disabled
	for item in steppers:
		var model = item.model
		item.label.text = model.value_labels[int(model.value)] if not model.value_labels.is_empty() else str(int(model.value))
		item.minus.disabled = not model.editable or model.value <= model.min_value
		item.plus.disabled = not model.editable or model.value >= model.max_value
		item.minus.modulate.a = 0.45 if item.minus.disabled else 1.0
		item.plus.modulate.a = 0.45 if item.plus.disabled else 1.0
		item.label.modulate.a = 1.0 if model.editable else 0.65

func set_ready(ready: bool) -> void:
	skin_button(page.start_button, "annullaPronto.png" if ready else "pronto.png")
	page.start_button.tooltip_text = "Annulla pronto" if ready else "Pronto"

func _copy_code() -> void:
	page.copied_code = str(page.code_button.get_meta("room_code", ""))
	DisplayServer.clipboard_set(page.copied_code)
	if copy_tween and copy_tween.is_valid():
		copy_tween.kill()
	copy_tween = create_tween()
	copy_tween.tween_property(page.code_label, "scale", Vector2.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	copy_tween.tween_callback(func(): page.copy_icon.texture = load(ICONS + "copy-success.svg"))
	copy_tween.tween_property(page.code_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _fit() -> void:
	if not is_inside_tree():
		return
	var viewport_size := get_viewport_rect().size
	var safe := Rect2(Vector2.ZERO, viewport_size)
	if OS.has_feature("web"):
		var encoded = JavaScriptBridge.eval("typeof window.biscaSafeArea === 'function' ? window.biscaSafeArea() : '[0,0,1,1]'", true)
		var fractions = JSON.parse_string(str(encoded))
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
	_layout_in_bounds(bounds, inverse * (viewport_size * 0.5))

func _layout_in_bounds(bounds: Rect2, screen_center: Vector2) -> void:
	# Center the visible lobby vertically on screen, not on the asymmetric
	# safe area or on the Back button. Keep 40px safe margins when fitting.
	var center := Vector2(bounds.get_center().x, clampf(screen_center.y, bounds.position.y, bounds.end.y))
	var available_height := maxf(0.0, 2.0 * minf(center.y - bounds.position.y, bounds.end.y - center.y))
	# Reserve equal space on both sides, so centering never overlaps Back.
	var factor := maxf(0.01, minf(bounds.size.x / (CONTENT_RECT.size.x + 264.0), available_height / CONTENT_RECT.size.y))
	content.scale = Vector2.ONE * factor
	content.position = center - CONTENT_RECT.get_center() * factor
	back_anchor.position = bounds.position
	back_anchor.scale = Vector2.ONE * factor

func stop_pop() -> void:
	if pop_tween and pop_tween.is_valid():
		pop_tween.kill()

func pop() -> void:
	stop_pop()
	_fit()
	pop_tween = create_tween().set_parallel(true)
	for index in blocks.size():
		var block := blocks[index]
		block.pivot_offset = block.size / 2
		block.scale = Vector2.ZERO
		pop_tween.tween_property(block, "scale", Vector2.ONE, 0.38).set_delay(index * 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
