@tool
extends ColorRect

# Lexispell's UIBackground palette and animated star material.
const STAR = preload("res://scenes/balatro/resources/denari.png")
const PATTERN_SHADER = preload("res://scenes/balatro/shaders/lexispell_background.gdshader")
var felt: ColorRect

func set_in_game(value: bool) -> void:
	if is_instance_valid(felt):
		felt.visible = value
		get_node("Stars").visible = not value

func _ready() -> void:
	color = Color(0.156863, 0.560784, 0.392157, 1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stars := ColorRect.new()
	stars.name = "Stars"
	stars.color = Color(0.329412, 0.729412, 0.474510, 1)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pattern := ShaderMaterial.new()
	pattern.shader = PATTERN_SHADER
	pattern.set_shader_parameter("tile_texture", STAR)
	pattern.set_shader_parameter("coppe", preload("res://scenes/balatro/resources/coppe.png"))
	pattern.set_shader_parameter("spade", preload("res://scenes/balatro/resources/spade.png"))
	pattern.set_shader_parameter("bastoni", preload("res://scenes/balatro/resources/bastoni.png"))
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
	felt = ColorRect.new()
	felt.name = "CartoonFelt"
	felt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var felt_material := ShaderMaterial.new()
	felt_material.shader = preload("res://scenes/balatro/shaders/cartoon_felt.gdshader")
	felt.material = felt_material
	add_child(felt)
	felt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	felt_material.set_shader_parameter("surface_size", size)
	resized.connect(func(): felt_material.set_shader_parameter("surface_size", size))
	felt.hide()
