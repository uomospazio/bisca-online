@tool
extends Control

var BACK: Texture2D:
	get:
		var settings = get_node_or_null("/root/GameSettings")
		return settings.back_texture() if settings else preload("res://scenes/balatro/trick_asset/mazzo_2/briscola/back/back1.png")

const LAYER_OFFSET := Vector2(0.4, -0.4)
const GameAudio = preload("res://scenes/balatro/scripts/game_audio.gd")

var bend: float = 0.0:
	set(value):
		bend = value
		_refresh_layers()

@export_range(0, 40) var card_count: int = 40:
	set(value):
		card_count = clampi(value, 0, 40)
		tooltip_text = "Mazzo: %d carte" % card_count
		_refresh_layers()

var _layers: Array[TextureRect] = []

func _ready() -> void:
	resized.connect(_refresh_layers)
	_refresh_layers()

func prepare_deal() -> void:
	GameAudio.play(self, GameAudio.SWIPE, -18.0)
	pivot_offset = size / 2.0
	z_index = 80

	var animation := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	animation.tween_property(self, "global_position", get_viewport_rect().size / 2.0 - size / 2.0, 0.4)
	animation.tween_property(self, "bend", 1.0, 0.16)
	animation.parallel().tween_property(self, "rotation", -0.12, 0.16)
	animation.tween_property(self, "bend", 0.0, 0.18)
	animation.parallel().tween_property(self, "rotation", 0.0, 0.18)
	await animation.finished

func return_home() -> void:
	GameAudio.play(self, GameAudio.SWIPE, -18.0)
	var animation := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	animation.tween_property(self, "position", _home_position(), 0.4)
	await animation.finished
	z_index = 0

func _home_position() -> Vector2:
	return get_parent().size + Vector2(-200, -267)

func place_home() -> void:
	position = _home_position()

func _refresh_layers() -> void:
	if not is_inside_tree():
		return

	var back := BACK
	if back == null:
		for layer in _layers:
			layer.hide()
		return

	# Non serve creare 40 TextureRect: ne mostriamo al massimo 12,
	# mantenendo comunque lo spessore visivo proporzionale al numero di carte.
	var visible_layers := mini(card_count, 12)

	while _layers.size() < visible_layers:
		var layer := TextureRect.new()
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_SCALE
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(layer)
		_layers.append(layer)

	for i in range(_layers.size()):
		var layer := _layers[i]

		if i >= visible_layers or card_count == 0:
			layer.hide()
			continue

		layer.show()
		layer.texture = back
		layer.size = size

		# Distribuisce lo spessore dell'intero mazzo sulle texture visibili.
		var source_index := 0.0
		if visible_layers > 1:
			source_index = float(i) * float(card_count - 1) / float(visible_layers - 1)

		layer.position = LAYER_OFFSET * source_index

		# Piccolo arco durante l'animazione di preparazione del deal.
		var t := 0.0 if visible_layers <= 1 else float(i) / float(visible_layers - 1)
		layer.position.y += -sin(t * PI) * 10.0 * bend
		layer.rotation = (t - 0.5) * 0.045 * bend

		var shade := 1.0 if i == visible_layers - 1 else 0.72
		layer.modulate = Color(shade, shade, shade, 1.0)
		layer.z_index = i

func top_global_position() -> Vector2:
	return get_global_transform() * (LAYER_OFFSET * maxi(card_count - 1, 0))
