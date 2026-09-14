extends Control

signal card_played(card: Control)

@export var played_scale: float = 0.9
@export var card_spacing: float = 24.0

var cards: Array[Control] = []
var drag_active: bool = false
var highlighted: bool = false
var layout_tween: Tween
var throws: Array[Tween] = []
var winning_card: Control
const LANDINGS := [
	Vector2(0, 100), # local: centered horizontally, closer to the hand
	Vector2(-600, 30), # left side
	Vector2(-470, -100), # upper-left curve
	Vector2(-260, -150),
	Vector2(0, -160), # upper center
	Vector2(260, -150),
	Vector2(470, -100), # upper-right curve
	Vector2(600, 30), # right side
]
# Le carte vengono lanciate dalle posizioni dei giocatori, ma restano sempre
# leggibili dal giocatore locale: niente carte capovolte o ruotate di lato.
const READABLE_ANGLES := [0.0, -0.18, -0.14, -0.08, 0.0, 0.08, 0.14, 0.18]

func clear_throws() -> void:
	for animation in throws:
		if animation.is_valid():
			animation.kill()
	throws.clear()
	set_winning_card(null)
	queue_redraw()

func set_winning_card(card: Control) -> void:
	if is_instance_valid(winning_card):
		winning_card.set_holo(false)
	winning_card = card
	if is_instance_valid(winning_card):
		winning_card.set_holo(true)
	queue_redraw()

func landing_position(card: Control) -> Vector2:
	var seat: int = card.get_meta("seat_id", 0)
	if seat == 0:
		var screen_center := get_viewport_rect().size / 2.0 + LANDINGS[0]
		var local_center := get_global_transform_with_canvas().affine_inverse() * screen_center
		return local_center - card.size / 2.0
	return size / 2.0 + LANDINGS[seat] - card.size / 2.0

func landing_rotation(card: Control) -> float:
	return READABLE_ANGLES[int(card.get_meta("seat_id", 0))]

func _ready() -> void:
	resized.connect(_arrange)

func contains_card(card: Control) -> bool:
	var center := card.get_global_transform() * (card.size / 2.0)
	return Rect2(Vector2.ZERO, size).has_point(get_global_transform().affine_inverse() * center)

func show_target(active: bool, aimed: bool = false) -> void:
	drag_active = active
	highlighted = aimed
	queue_redraw()

func _draw() -> void:
	if not drag_active:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.8, 1.0, 0.85, 0.07 if highlighted else 0.025)
	style.border_color = Color(0.8, 1.0, 0.85, 0.45 if highlighted else 0.15)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	draw_style_box(style, Rect2(Vector2.ZERO, size))

func play_card(card: Control, animated: bool = true, keep_position: bool = false) -> void:
	if card.tween_hover and card.tween_hover.is_running():
		card.tween_hover.kill()
	if card.tween_handle and card.tween_handle.is_running():
		card.tween_handle.kill()
	card.is_played = true
	card.play_preview = false
	card.played_scale = played_scale
	# Preserve the screen position when changing parent. The launch tween must
	# start exactly where the card was held or where the opponent is seated.
	card.reparent(self, true)
	cards.append(card)
	card.disabled = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if keep_position:
		card_played.emit(card)
		return
	if not animated:
		card.position = landing_position(card)
		card.rotation = landing_rotation(card)
		card.scale = Vector2.ONE * played_scale
		card_played.emit(card)
		return
	var origin := card.position
	preload("res://scenes/balatro/scripts/game_audio.gd").play(self, preload("res://scenes/balatro/scripts/game_audio.gd").CARD)
	var destination := landing_position(card)
	var initial_angle := card.rotation
	var initial_scale := card.scale
	card.z_index = 40
	var animation := create_tween()
	throws.append(animation)
	animation.tween_method(func(progress: float):
		var eased := 1.0 - pow(1.0 - progress, 3)
		card.position = origin.lerp(destination, eased) + Vector2(0, -55.0 * sin(progress * PI))
		card.rotation = lerp_angle(initial_angle, landing_rotation(card), eased)
		card.scale = initial_scale.lerp(Vector2.ONE * played_scale, eased)
		if card.has_node("OwnerLabel"):
			card.get_node("OwnerLabel").rotation = -card.rotation
	, 0.0, 1.0, 0.38)
	animation.tween_callback(func(): card.z_index = 0)
	card_played.emit(card)

func _arrange() -> void:
	if cards.is_empty():
		return
	clear_throws()
	for card in cards:
		card.position = landing_position(card)
		card.rotation = landing_rotation(card)
		card.scale = Vector2.ONE * played_scale
