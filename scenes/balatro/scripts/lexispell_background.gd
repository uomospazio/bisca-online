@tool
extends ColorRect

# Lexispell's UIBackground palette and animated star material.
const STAR = preload("res://scenes/balatro/resources/minibisca.png")
const PATTERN_SHADER = preload("res://scenes/balatro/shaders/lexispell_background.gdshader")

func _ready() -> void:
	color = Color(0.341176, 0.509804, 0.423529, 1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stars := ColorRect.new()
	stars.name = "Stars"
	stars.color = Color(0.454902, 0.670588, 0.556863, 1)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pattern := ShaderMaterial.new()
	pattern.shader = PATTERN_SHADER
	pattern.set_shader_parameter("tile_texture", STAR)
	pattern.set_shader_parameter("tile_factor", 1.0)
	pattern.set_shader_parameter("tile_rotation_speed", 25.0)
	pattern.set_shader_parameter("tile_spacing", -1.8)
	pattern.set_shader_parameter("scrolling_speed", 0.25)
	pattern.set_shader_parameter("scrolling_dir", Vector2(0.5, 0.5))
	stars.material = pattern
	add_child(stars)
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pattern.set_shader_parameter("size", size)
	resized.connect(func(): pattern.set_shader_parameter("size", size))
