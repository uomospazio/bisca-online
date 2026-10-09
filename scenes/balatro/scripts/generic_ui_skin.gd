extends RefCounted
## Procedural Figma skin, shared by panels and buttons.
const SHADER = preload("res://scenes/balatro/shaders/generic_ui.gdshader")
const BUTTON_RATIO := 160.0 / 46.0

static func apply(control: Control, pill := false, padding := 24.0) -> void:
	if control.has_meta("generic_ui_skin"): return
	control.set_meta("generic_ui_skin", true)
	var empty := StyleBoxEmpty.new()
	for side in ["left", "right", "top", "bottom"]:
		empty.set("content_margin_" + side, padding if not pill else 12.0)
	if control is PanelContainer or control is Panel:
		control.add_theme_stylebox_override("panel", empty)
	elif control is Button:
		if not control is RoundedSquareButton:
			preload("res://scenes/balatro/scripts/menu_button_hover.gd").attach(control)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
			control.add_theme_stylebox_override(state, empty)
	# Node2D keeps the visual out of Container layout calculations.
	var layer := Node2D.new()
	layer.show_behind_parent = true
	control.add_child(layer)
	var background := ColorRect.new()
	layer.add_child(background)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	control.set_meta("generic_ui_material", material)
	material.set_shader_parameter("pill_highlight", pill)
	if not pill:
		material.set_shader_parameter("fill_top", Color("1D1A48"))
		material.set_shader_parameter("fill_bottom", Color("1D1A48"))
	background.material = material
	var fit := func():
		# Figma reference sizes: box 350x350, button 160x46.
		# The shorter box edge gives non-square panels uniform corners/strokes.
		var design_scale := maxf(0.001, control.size.y / 46.0 if pill else minf(control.size.x, control.size.y) / 350.0)
		var outline := 2.0 * design_scale
		background.position = -Vector2.ONE * outline
		background.size = control.size + Vector2.ONE * outline * 2.0
		material.set_shader_parameter("body_size", control.size)
		material.set_shader_parameter("inner_border", (3.0 if pill else 5.0) * design_scale)
		material.set_shader_parameter("outer_border", outline)
		material.set_shader_parameter("corner_radius", control.size.y / 2 if pill else 30.0 * design_scale)
	control.resized.connect(fit)
	fit.call()
	if control is Button:
		var button := control as Button
		var refresh := func():
			var value := 0.6 if button.disabled else (0.82 if button.is_pressed() else (1.08 if button.is_hovered() or button.has_focus() else 1.0))
			material.set_shader_parameter("brightness", value)
		button.draw.connect(refresh)
		button.mouse_entered.connect(refresh)
		button.mouse_exited.connect(refresh)
		button.focus_entered.connect(refresh)
		button.focus_exited.connect(refresh)
		button.button_down.connect(refresh)
		button.button_up.connect(refresh)
		refresh.call()
