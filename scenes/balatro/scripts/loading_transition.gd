extends CanvasLayer

# Lexispell show_noise/hide_noise: 0.6 seconds at animation speed 0.75.
const DURATION := 0.8
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const SHADER = preload("res://scenes/balatro/shaders/loading_transition.gdshader")
var surface: ColorRect
var caption: RichTextLabel
var noise_texture: NoiseTexture2D
var busy := false

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	surface = ColorRect.new()
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_STOP
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color.BLACK])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.seed = 29
	noise.frequency = 0.0382
	noise.fractal_octaves = 1
	noise.cellular_jitter = 1.125
	noise_texture = NoiseTexture2D.new()
	noise_texture.noise = noise
	noise_texture.seamless = true
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("base_color", Color("2a2438"))
	material.set_shader_parameter("factor", 0.0)
	material.set_shader_parameter("gradient_texture", gradient_texture)
	material.set_shader_parameter("gradient_fixed", true)
	material.set_shader_parameter("shape_texture", noise_texture)
	material.set_shader_parameter("shape_tiling", 0.445)
	material.set_shader_parameter("shape_scroll", Vector2(0.05, 0.05))
	surface.material = material
	surface.resized.connect(func(): material.set_shader_parameter("node_resolution", surface.size))
	material.set_shader_parameter("node_resolution", get_viewport().get_visible_rect().size)
	caption = RichTextLabel.new()
	add_child(caption)
	caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caption.position = get_viewport().get_visible_rect().size / 2.0 - Vector2(350, 75)
	caption.size = Vector2(700, 150)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.bbcode_enabled = true
	caption.scroll_active = false
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("normal_font", FONT)
	caption.add_theme_font_size_override("normal_font_size", 44)
	caption.add_theme_color_override("default_color", Color("fdfdfb"))
	caption.add_theme_color_override("font_outline_color", Color("6f5fa8"))
	caption.add_theme_constant_override("outline_size", 32)
	caption.add_theme_color_override("font_shadow_color", Color("2a2438"))
	caption.add_theme_constant_override("shadow_outline_size", 32)
	caption.add_theme_constant_override("shadow_offset_x", 3)
	caption.add_theme_constant_override("shadow_offset_y", 5)
	caption.text = "[wave amp=50.0 freq=5.0 connected=1]LOADING[/wave]"
	hide()

func _input(_event: InputEvent) -> void:
	if busy:
		get_viewport().set_input_as_handled()

func cover() -> void:
	busy = true
	caption.modulate.a = 0.0
	surface.material.set_shader_parameter("factor", 0.0)
	# NoiseTexture generates asynchronously; do not reveal an unready mask.
	if noise_texture.get_image() == null:
		await noise_texture.changed
	show()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(surface.material, "shader_parameter/factor", 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(caption, "modulate:a", 1.0, DURATION / 3.0).set_delay(DURATION * 2.0 / 3.0)
	await tween.finished

func uncover() -> void:
	# Give the centered loading text a short readable hold while the table is ready.
	await get_tree().create_timer(0.25).timeout
	var tween := create_tween().set_parallel(true)
	tween.tween_property(caption, "modulate:a", 0.0, DURATION / 3.0)
	tween.tween_property(surface.material, "shader_parameter/factor", 0.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	hide()
	busy = false
