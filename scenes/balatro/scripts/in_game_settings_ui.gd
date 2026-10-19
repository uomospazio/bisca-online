extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"

const ART_SETTINGS := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/settingsUI/"
const ART_ROOM := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/InLobbyUI/"
var pause_owner: CanvasLayer
var settings: Node
var voice: Node
var multiplayer_mode := false
var design := Vector2(1200, 678)
var restart_button: Button
var continue_button: Button
var status: Label
var toggles: Dictionary = {}
var sliders: Dictionary = {}
var numbers: Dictionary = {}
var participant_rows: Control
var participant_sliders: Dictionary = {}
var participant_numbers: Dictionary = {}
var roster_key := ""
var entrance: Tween
var questions_button: Button

func setup_pause(owner_pause: CanvasLayer) -> void:
	pause_owner = owner_pause
	settings = get_node("/root/GameSettings")
	voice = get_node("/root/VoiceChat")
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	font = preload("res://scenes/balatro/fonts/Comic Lemon.otf").duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	set_meta("cartoon_style_children_excluded", true)
	settings.changed.connect(sync)
	voice.changed.connect(sync)
	get_viewport().size_changed.connect(_fit)
	build(false)

func build(multi: bool) -> void:
	multiplayer_mode = multi
	if entrance and entrance.is_valid(): entrance.kill()
	if is_instance_valid(composition):
		remove_child(composition)
		composition.queue_free()
	toggles.clear()
	sliders.clear()
	numbers.clear()
	participant_sliders.clear()
	participant_numbers.clear()
	roster_key = ""
	composition = Control.new()
	add_child(composition)
	design = Vector2(1838, 772) if multi else Vector2(1200, 678)
	composition.size = design
	_image(composition, ART_SETTINGS + ("inGameMultiPanel.png" if multi else "inGameSoloPanel.png"), Rect2(Vector2.ZERO, design))
	questions_button = _button(composition, "res://scenes/balatro/trick_asset/ui_bisca/pngUI/assistenteUI/buttonAssistente.png", Rect2(1720 if multi else 1080, 32, 68, 68), func(): preload("res://scenes/balatro/scripts/assistant_chat.gd").open(pause_owner.screen))
	questions_button.tooltip_text = "Domande e risposte"
	_toggle("show_thrown_objects", Vector2(1695, 156) if multi else Vector2(1030, 134), func(): settings.set_value("show_thrown_objects", not settings.values.show_thrown_objects))
	for key in ["main", "effects"]:
		var y: float = (356 if multi else 322) + (68 if key == "effects" else 0)
		var slider := _slider(composition, Rect2(1390 if multi else 665, y, 250 if multi else 340, 50))
		slider.value_changed.connect(func(value): settings.set_value(key, value))
		sliders[key] = slider
		var number := _label(composition, "", Rect2(1680 if multi else 1026, y + 5, 84, 50), 25)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		numbers[key] = number
	if multi:
		_toggle("microphone", Vector2(1695, 500), _toggle_microphone)
		_toggle("voice", Vector2(790, 60), voice.toggle_audio)
		participant_rows = Control.new()
		composition.add_child(participant_rows)
	var button_y := 630 if multi else 542
	_button(composition, ART_SETTINGS + "quit.png", Rect2(932 if multi else 42, button_y, 316, 108), func(): pause_owner._confirm_leave(false))
	restart_button = _button(composition, ART_SETTINGS + "ricomincia.png", Rect2(442, button_y, 316, 108), func(): pause_owner._confirm_leave(true))
	restart_button.visible = not multi
	continue_button = _button(composition, ART_SETTINGS + "continua.png", Rect2(1488 if multi else 842, button_y, 316, 108), pause_owner.close)
	status = _label(composition, "", Rect2(0, design.y + 8, design.x, 42), 22)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sync()
	_fit()

func _toggle_microphone() -> void:
	var turn_on: bool = not settings.values.microphone_enabled or voice.muted
	# The toggle replaces the old push-to-talk screen button.
	if turn_on: settings.set_value("push_to_talk", false)
	settings.set_value("microphone_enabled", turn_on)
	voice.set_muted(not turn_on)

func _toggle(key: String, at: Vector2, callback: Callable) -> void:
	toggles[key] = _button(composition, ART_ROOM + "toggleOff.png", Rect2(at, Vector2(72, 42)), callback)

func _slider(parent: Node, rect: Rect2) -> HSlider:
	var slider := HSlider.new()
	parent.add_child(slider)
	slider.position = rect.position
	slider.size = rect.size
	slider.max_value = 100
	slider.step = 1
	for state in ["slider", "grabber_area", "grabber_area_highlight"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("343047") if state == "slider" else Color("26d33a")
		style.set_corner_radius_all(10)
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		slider.add_theme_stylebox_override(state, style)
	slider.add_theme_icon_override("grabber", preload("res://scenes/balatro/visuals/settings_knob.svg"))
	slider.add_theme_icon_override("grabber_highlight", preload("res://scenes/balatro/visuals/settings_knob_hover.svg"))
	return slider

func _toggle_state(button: Button, active: bool) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var skin := StyleBoxTexture.new()
		skin.texture = UiLocale.resource(ART_ROOM + ("toggleOn.png" if active else "toggleOff.png"))
		skin.modulate_color = Color(0.5, 0.5, 0.5) if button.disabled else Color.WHITE
		button.add_theme_stylebox_override(state, skin)

func sync() -> void:
	if not is_instance_valid(composition): return
	_toggle_state(toggles.show_thrown_objects, settings.values.show_thrown_objects)
	for key in sliders:
		sliders[key].set_value_no_signal(settings.values[key])
		numbers[key].text = str(int(settings.values[key]))
	if multiplayer_mode:
		toggles.voice.disabled = not voice.available()
		toggles.voice.tooltip_text = voice.status
		_toggle_state(toggles.voice, voice.enabled or voice.pending)
		_toggle_state(toggles.microphone, settings.values.microphone_enabled and not voice.muted)
		toggles.microphone.tooltip_text = "Il tuo microfono (la chat vocale deve essere attiva)"
		_render_participants()
		status.text = "LA PARTITA E IL TIMER CONTINUANO · " + voice.status
	else:
		status.text = "PARTITA IN PAUSA"

func _render_participants() -> void:
	var participants: Array = []
	for index in voice.people.size():
		var person: Dictionary = voice.people[index]
		if index == voice.my_slot or person.get("bot", false) or not person.get("connected", true): continue
		var id := str(person.get("id", person.get("voice_id", "")))
		if id.is_empty(): continue
		participants.append({"id": id, "name": str(person.get("name", "Giocatore"))})
	var next_key := JSON.stringify(participants)
	if next_key != roster_key or participant_rows.get_child_count() == 0:
		roster_key = next_key
		for child in participant_rows.get_children():
			participant_rows.remove_child(child)
			child.queue_free()
		participant_sliders.clear()
		participant_numbers.clear()
		for index in 7:
			var y := 108 + index * 88
			if index >= participants.size():
				_participant_slot(Rect2(58, y, 820, 76), true)
				continue
			var person: Dictionary = participants[index]
			var id: String = person.id
			_participant_slot(Rect2(58, y, 820, 76), false)
			var label := _label(participant_rows, person.name, Rect2(86, y, 300, 76), 27)
			label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.clip_text = true
			var slider := _slider(participant_rows, Rect2(410, y + 13, 305, 50))
			slider.value_changed.connect(func(value):
				voice.set_player_volume(id, value)
				participant_numbers[id].text = str(int(value)))
			participant_sliders[id] = slider
			var value_box := Panel.new()
			participant_rows.add_child(value_box)
			value_box.position = Vector2(752, y + 13)
			value_box.size = Vector2(84, 50)
			value_box.mouse_filter = MOUSE_FILTER_IGNORE
			var value_style := StyleBoxFlat.new()
			value_style.bg_color = Color("392c88")
			value_style.border_color = Color("8968e9")
			value_style.set_border_width_all(2)
			value_style.set_corner_radius_all(15)
			value_box.add_theme_stylebox_override("panel", value_style)
			var number := _label(participant_rows, "", Rect2(752, y + 18, 84, 50), 25)
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			participant_numbers[id] = number
	for id in participant_sliders:
		participant_sliders[id].set_value_no_signal(voice.player_volume(id))
		participant_numbers[id].text = str(int(voice.player_volume(id)))

func _participant_slot(rect: Rect2, empty: bool) -> void:
	# Draw the rounded ends and text independently: stretching the lobby PNG
	# also stretched its corners, outline and baked-in EMPTY lettering.
	var panel := Panel.new()
	participant_rows.add_child(panel)
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color("2b253f") if empty else Color("1d1a48")
	skin.border_color = Color.BLACK
	skin.set_border_width_all(3)
	skin.set_corner_radius_all(int(rect.size.y / 2))
	panel.add_theme_stylebox_override("panel", skin)
	if empty:
		var label := _label(participant_rows, "EMPTY", rect, 27)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("b1a7cb"))
	else:
		var inner := Panel.new()
		panel.add_child(inner)
		inner.position = Vector2(4, 4)
		inner.size = rect.size - Vector2(8, 8)
		inner.mouse_filter = MOUSE_FILTER_IGNORE
		var border := skin.duplicate() as StyleBoxFlat
		border.border_color = Color("8968e9")
		border.set_border_width_all(2)
		border.set_corner_radius_all(int(inner.size.y / 2))
		inner.add_theme_stylebox_override("panel", border)

func open(multi: bool) -> void:
	if multi != multiplayer_mode: build(multi)
	sync()
	_fit()
	if entrance and entrance.is_valid(): entrance.kill()
	var target := composition.scale
	composition.pivot_offset = design / 2
	composition.scale = Vector2.ZERO
	entrance = create_tween()
	entrance.tween_property(composition, "scale", target, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _layout(bounds: Rect2) -> void:
	if not is_instance_valid(composition): return
	var factor := maxf(0.01, minf(bounds.size.x / design.x, bounds.size.y / (design.y + 60)))
	composition.pivot_offset = design / 2
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center() - design / 2
