extends Range

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
var editable := true:
	set(next):
		editable = next
		_refresh()
var previous: Button
var next_button: Button
var caption: Label
var value_labels: Array[String] = []

func setup(font: Font) -> void:
	custom_minimum_size = Vector2(264, 64)
	var row := HBoxContainer.new()
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 28)
	previous = _arrow(row, "arrow-left", -1)
	caption = Label.new()
	caption.custom_minimum_size.x = 80
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font", font)
	caption.add_theme_font_size_override("font_size", 34)
	caption.add_theme_color_override("font_color", Style.TEXT)
	row.add_child(caption)
	next_button = _arrow(row, "arrow-right", 1)
	value_changed.connect(func(_value): _refresh())
	_refresh()

func _arrow(row: HBoxContainer, icon_name: String, direction: int) -> Button:
	var button := RoundedSquareButton.new()
	row.add_child(button)
	button.custom_minimum_size = Vector2(64, 64)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 30)
	button.icon = load("res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % icon_name)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var color := Style.DISABLED if state == "disabled" else (Style.HOVER if state in ["hover", "focus"] else Style.NORMAL)
		var style := Style.button_style(color)
		style.set_corner_radius_all(32)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(func():
		if editable:
			value += direction
	)
	return button

func _refresh() -> void:
	if caption == null or next_button == null:
		return
	caption.text = value_labels[int(value)] if not value_labels.is_empty() else str(int(value))
	previous.disabled = not editable or value <= min_value
	next_button.disabled = not editable or value >= max_value
	for button in [previous, next_button]:
		if button.disabled:
			if button.hover_tween and button.hover_tween.is_valid(): button.hover_tween.kill()
			button.scale = Vector2.ONE
			button.rotation = 0.0
