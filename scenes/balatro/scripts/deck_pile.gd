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
		queue_redraw()

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
	return get_parent().size + Vector2(-1500, -267)

func place_home() -> void:
	position = _home_position()

@export_range(0, 40) var card_count: int = 40:
	set(value):
		card_count = clampi(value, 0, 40)
		tooltip_text = "Mazzo: %d carte" % card_count
		queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	if card_count == 0:
		return
	draw_texture_rect(BACK, Rect2(Vector2(4, 12), size), false, Color(0, 0, 0, 0.2))
	for index in range(card_count):
		var shade := 1.0 if index == card_count - 1 else 0.72
		if is_zero_approx(bend):
			draw_texture_rect(BACK, Rect2(LAYER_OFFSET * index, size), false, Color(shade, shade, shade))
			continue
		# Narrow vertical slices give the pack a gentle visible bend before dealing.
		for slice in range(12):
			var fraction := float(slice) / 12.0
			var width := size.x / 12.0 + 0.3
			var offset_y := -sin((fraction + 1.0 / 24.0) * PI) * 16.0 * bend
			var destination := Rect2(LAYER_OFFSET * index + Vector2(size.x * fraction, offset_y), Vector2(width, size.y))
			var source := Rect2(BACK.get_size() * Vector2(fraction, 0), BACK.get_size() * Vector2(1.0 / 12.0, 1))
			draw_texture_rect_region(BACK, destination, source, Color(shade, shade, shade))

func top_global_position() -> Vector2:
	return get_global_transform() * (LAYER_OFFSET * maxi(card_count - 1, 0))
