extends CanvasLayer
## Schermata iniziale animata, chiusa dopo l'inizializzazione del menu.

var surface: ColorRect
var logo: TextureRect
var entrance: Tween

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	surface = ColorRect.new()
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.mouse_filter = Control.MOUSE_FILTER_STOP
	var background := ShaderMaterial.new()
	background.shader = preload("res://scenes/balatro/shaders/menu_suits.gdshader")
	for suit in ["denari", "coppe", "spade", "bastoni"]:
		background.set_shader_parameter(suit, load("res://scenes/balatro/resources/%s.png" % suit))
	surface.material = background
	logo = TextureRect.new()
	logo.texture = preload("res://scenes/balatro/trick_asset/ui_bisca/logo.svg")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.add_child(logo)
	surface.resized.connect(_layout)
	_layout()
	logo.scale = Vector2.ONE * 0.65
	logo.modulate.a = 0.0
	entrance = create_tween().set_parallel(true)
	entrance.tween_property(logo, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(logo, "modulate:a", 1.0, 0.3)

func _layout() -> void:
	var width := minf(760.0, surface.size.x * 0.55)
	logo.size = Vector2(width, width * 202.0 / 563.0)
	logo.position = (surface.size - logo.size) / 2.0
	logo.pivot_offset = logo.size / 2.0
	surface.material.set_shader_parameter("surface_size", surface.size)
	surface.material.set_shader_parameter("clear_center_size", logo.size + Vector2(150, 130))

func finish() -> void:
	# Il chiamante ha terminato setup, segnali e layout; attendi un frame
	# prima di rivelarlo. La rete continua ad inizializzarsi in background.
	await get_tree().process_frame
	if entrance.is_running():
		await entrance.finished
	await get_tree().create_timer(0.45).timeout
	var exit := create_tween().set_parallel(true)
	exit.tween_property(logo, "scale", Vector2.ONE * 1.12, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit.tween_property(logo, "modulate:a", 0.0, 0.3)
	await exit.finished
	var reveal := create_tween()
	reveal.tween_property(surface, "modulate:a", 0.0, 0.3)
	await reveal.finished
	queue_free()
