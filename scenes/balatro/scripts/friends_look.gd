extends RefCounted
const SHADER = preload("res://scenes/balatro/scripts/friends_gloss.gdshader")

static func decorate(control: Control, radius: float = 28.0, color := Color("262044")) -> void:
	var art := ColorRect.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.show_behind_parent = true
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("radius", radius)
	material.set_shader_parameter("base_color", color)
	art.material = material
	control.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.resized.connect(func(): material.set_shader_parameter("extent", control.size))
	material.set_shader_parameter("extent", control.size)
	if control is Button:
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			control.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		control.mouse_entered.connect(func(): material.set_shader_parameter("emphasis", 0.7))
		control.mouse_exited.connect(func(): material.set_shader_parameter("emphasis", 0.0))
		control.button_down.connect(func(): material.set_shader_parameter("emphasis", -0.4))
		control.button_up.connect(func(): material.set_shader_parameter("emphasis", 0.0))

static func padding(amount: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_content_margin_all(amount)
	return style
