extends Control

const StyledButton = preload("res://scenes/balatro/scripts/rounded_square_button.gd")
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")

var preview: TextureRect
var edit_button: Button
var editing_controls: Array[Control] = []
var selected := 1
var switching := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	preview = TextureRect.new()
	preview.position = Vector2(90, 0)
	preview.size = Vector2(180, 272)
	preview.pivot_offset = preview.size / 2.0
	preview.rotation_degrees = 7.0
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)

	edit_button = _button(
		Vector2(246, -24),
		Vector2(64, 64),
		"edit",
		func(): _edit(true)
	)

	editing_controls.append(
		_button(
			Vector2(0, 104),
			Vector2(64, 64),
			"arrow-left",
			func(): _cycle(-1)
		)
	)

	editing_controls.append(
		_button(
			Vector2(296, 104),
			Vector2(64, 64),
			"arrow-right",
			func(): _cycle(1)
		)
	)

	var confirm := _button(
		Vector2(60, 304),
		Vector2(240, 64),
		"",
		_confirm
	)
	confirm.text = "CONFERMA"
	editing_controls.append(confirm)

	reset_preview()


func _button(
	at: Vector2,
	dimensions: Vector2,
	icon_name: String,
	callback: Callable
) -> Button:
	var button := StyledButton.new()
	add_child(button)

	button.position = at
	button.size = dimensions
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Style.TEXT)
	button.add_theme_color_override("font_hover_color", Style.TEXT)

	if not icon_name.is_empty():
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 28)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.icon = load(
			"res://scenes/balatro/trick_asset/ui_bisca/%s.svg" % icon_name
		)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var style := Style.button_style(
			Style.HOVER if state in ["hover", "focus"] else Style.NORMAL
		)

		if not icon_name.is_empty():
			style.set_corner_radius_all(32)

		button.add_theme_stylebox_override(state, style)

	button.pressed.connect(callback)
	return button


func reset_preview() -> void:
	selected = int(get_node("/root/GameSettings").values.deck_back)
	preview.texture = get_node("/root/GameSettings").back_texture(selected)
	_edit(false, false)


func _edit(value: bool, animate := true) -> void:
	if switching and animate:
		return

	var outgoing: Array[Control] = []
	var incoming: Array[Control] = []

	if value:
		outgoing.append(edit_button)
		incoming = editing_controls
	else:
		outgoing = editing_controls
		incoming.append(edit_button)

	if not animate:
		edit_button.visible = not value
		edit_button.scale = Vector2.ONE

		for control in editing_controls:
			control.visible = value
			control.scale = Vector2.ONE

		switching = false
		return

	switching = true
	_animate_control_swap(outgoing, incoming)


func _animate_control_swap(
	outgoing: Array[Control],
	incoming: Array[Control]
) -> void:
	var tween := create_tween()

	# Prepara i controlli che stanno sparendo.
	for control in outgoing:
		control.pivot_offset = control.size / 2.0
		control.scale = Vector2.ONE
		control.set("hover_animate", false)

	# SPARIZIONE:
	# solo rimpicciolimento.
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)

	for control in outgoing:
		tween.tween_property(
			control,
			"scale",
			Vector2(0.5, 0.5),
			0.18
		)

	tween.set_parallel(false)

	# Nasconde i vecchi e prepara i nuovi già rimpiccioliti.
	tween.tween_callback(func():
		for control in outgoing:
			control.hide()
			control.scale = Vector2.ONE

		for control in incoming:
			control.pivot_offset = control.size / 2.0
			control.scale = Vector2(0.5, 0.5)
			control.set("hover_animate", false)
			control.show()
	)

	# APPARIZIONE:
	# solo ingrandimento con effetto pop.
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)

	for control in incoming:
		tween.tween_property(
			control,
			"scale",
			Vector2.ONE,
			0.28
		)

	tween.set_parallel(false)

	# Ripristina lo stato normale e riattiva l'hover.
	tween.tween_callback(func():
		for control in incoming:
			control.scale = Vector2.ONE
			control.set("hover_animate", true)

		for control in outgoing:
			control.set("hover_animate", true)

		switching = false
	)


func _cycle(direction: int) -> void:
	selected = wrapi(selected - 1 + direction, 0, 12) + 1
	preview.texture = get_node("/root/GameSettings").back_texture(selected)


func _confirm() -> void:
	get_node("/root/GameSettings").set_value("deck_back", selected)
	get_node("/root/GameSettings").save_preferences()
	_edit(false)
