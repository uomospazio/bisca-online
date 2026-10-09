extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"
## Menu-only replacement for system confirmation/notice windows.
signal confirmed
signal canceled
const DialogSkin = preload("res://scenes/balatro/scripts/generic_ui_skin.gd")
var title := "":
	set(value):
		title = value
		if is_instance_valid(heading): heading.text = value
var dialog_text := "":
	set(value):
		dialog_text = value
		if is_instance_valid(message):
			message.text = value
			message.visible = not value.is_empty()
var ok_button_text := "OK":
	set(value):
		ok_button_text = value
		if is_instance_valid(ok): ok.text = value
var cancel_button_text := "ANNULLA":
	set(value):
		cancel_button_text = value
		if is_instance_valid(cancel): cancel.text = value
var body: VBoxContainer
var panel: PanelContainer
var heading: Label
var message: Label
var ok: Button
var cancel: Button
var requested_size := Vector2(850, 500)
var pop_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	z_index = 110
	set_meta("cartoon_style_children_excluded", true)
	font = preload("res://scenes/balatro/fonts/Comic Lemon.otf").duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	panel = PanelContainer.new()
	add_child(panel)
	DialogSkin.apply(panel, false, 32)
	var layout := VBoxContainer.new()
	panel.add_child(layout)
	layout.add_theme_constant_override("separation", 24)
	heading = _label(layout, title, Rect2(), 42)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := preload("res://scenes/balatro/scripts/touch_scroll.gd").new()
	layout.add_child(scroll)
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body = VBoxContainer.new()
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	scroll.add_child(body)
	message = _label(body, dialog_text, Rect2(), 28)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.visible = not dialog_text.is_empty()
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 24)
	layout.add_child(actions)
	cancel = _action(actions, cancel_button_text, func(): hide(); canceled.emit())
	cancel.hide()
	ok = _action(actions, ok_button_text, func(): hide(); confirmed.emit())
	get_viewport().size_changed.connect(_fit)
	hide()

func _action(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.text = text
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 26)
	button.custom_minimum_size = Vector2(300, 300 / DialogSkin.BUTTON_RATIO)
	DialogSkin.apply(button, true)
	button.pressed.connect(callback)
	RoundedSquareButton.ButtonAudio.attach(button)
	return button

func get_ok_button() -> Button: return ok
func get_cancel_button() -> Button:
	cancel.show()
	return cancel
func get_label() -> Label: return message

func popup_centered(dimensions := Vector2i(850, 500)) -> void:
	requested_size = Vector2(maxi(dimensions.x, 720), maxi(dimensions.y, 360))
	cancel.visible = cancel.visible or not canceled.get_connections().is_empty()
	show()
	panel.modulate.a = 0.0
	_fit()
	# Wrapped labels need a layout pass at the actual width before measuring height.
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_visible_in_tree(): return
	_fit()
	panel.modulate.a = 1.0
	if pop_tween and pop_tween.is_valid(): pop_tween.kill()
	var target := panel.scale
	panel.scale = Vector2.ZERO
	pop_tween = create_tween()
	pop_tween.tween_property(panel, "scale", target, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _layout(bounds: Rect2) -> void:
	if not is_instance_valid(panel): return
	panel.size = requested_size
	panel.pivot_offset = panel.size / 2
	panel.position = bounds.get_center() - panel.size / 2
	panel.scale = Vector2.ONE * minf(1.0, minf(bounds.size.x / panel.size.x, bounds.size.y / panel.size.y))

func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		hide()
		canceled.emit()
		get_viewport().set_input_as_handled()
