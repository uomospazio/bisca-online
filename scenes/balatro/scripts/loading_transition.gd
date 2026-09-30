extends CanvasLayer

# Lexispell show_noise/hide_noise: 0.6 seconds at animation speed 0.75.
const DURATION := 0.8
const SHADER = preload("res://scenes/balatro/shaders/loading_transition.gdshader")
var surface: ColorRect
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
	hide()

func _input(_event: InputEvent) -> void:
	if busy:
		get_viewport().set_input_as_handled()

func cover() -> void:
	busy = true
	surface.material.set_shader_parameter("factor", 0.0)
	# NoiseTexture generates asynchronously; do not reveal an unready mask.
	if noise_texture.get_image() == null:
		await noise_texture.changed
	show()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(surface.material, "shader_parameter/factor", 1.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func uncover() -> void:
	# Rimuove la copertura appena la partita è pronta, senza testo centrale.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(surface.material, "shader_parameter/factor", 0.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	hide()
	busy = false
