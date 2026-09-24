extends Button

const CardData = preload("res://scenes/balatro/scripts/card_data.gd")
const ButtonAudio = preload("res://scenes/balatro/scripts/button_audio.gd")
var BACK: Texture2D:
	get:
		var settings = get_node_or_null("/root/GameSettings")
		return settings.back_texture() if settings else preload("res://scenes/balatro/trick_asset/mazzo_2/briscola/back/back1.png")
var data: CardData
var face_down: bool = false
var is_dealing: bool = false
var joker_arrow: Polygon2D
var holo_active := false

func set_holo(active: bool) -> void:
	holo_active = active
	if is_node_ready():
		card_texture.material.set_shader_parameter("holo_strength", 1.0 if active and not face_down else 0.0)

func show_joker_direction(high: bool) -> void:
	if face_down:
		return
	if not is_instance_valid(joker_arrow):
		joker_arrow = Polygon2D.new()
		add_child(joker_arrow)
		joker_arrow.z_index = 10
	# Arrow outside the top-right corner; no font glyph dependency.
	joker_arrow.position = Vector2(size.x + 24.0, 4.0)
	joker_arrow.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(16, -3), Vector2(6, -3),
		Vector2(6, 18), Vector2(-6, 18), Vector2(-6, -3), Vector2(-16, -3)
	])
	joker_arrow.rotation = 0.0 if high else PI
	joker_arrow.color = Color("42c985") if high else Color("e85d68")

func set_face_down(value: bool) -> void:
	face_down = value
	_apply_card_data()

func set_card_data(value: CardData) -> void:
	data = value
	if is_node_ready():
		_apply_card_data()

func _apply_card_data() -> void:
	card_texture.texture = BACK if face_down else data.texture
	set_holo(holo_active)
	tooltip_text = "" if face_down else data.display_name

func _get_tooltip(_at_position: Vector2) -> String:
	var settings := get_node_or_null("/root/GameSettings")
	if face_down or (settings and not settings.values.tooltips):
		return ""
	return tooltip_text

signal drag_started(card: Control)
signal drag_moved(card: Control)
signal drag_ended(card: Control)

@export var angle_x_max: float = 6.0
@export var angle_y_max: float = 6.0
@export var max_offset_shadow: float = 50.0

@export_category("Oscillator")
@export var spring: float = 150.0
@export var damp: float = 10.0
@export var velocity_multiplier: float = 2.0

var displacement: float = 0.0 
var oscillator_velocity: float = 0.0

var tween_rot: Tween
var tween_hover: Tween
var tween_handle: Tween

var last_mouse_pos: Vector2
var mouse_velocity: Vector2
var following_mouse: bool = false
var last_pos: Vector2
var velocity: Vector2
var resting_z_index: int
var play_preview: bool = false
var is_played: bool = false
var drag_cancelled: bool = false
var played_scale: float = 0.95

@onready var card_texture: TextureRect = $CardTexture
@onready var shadow = $Shadow

func _ready() -> void:
	# Convert to radians because lerp_angle is using that
	angle_x_max = deg_to_rad(angle_x_max)
	angle_y_max = deg_to_rad(angle_y_max)
	if data:
		_apply_card_data()

func _process(delta: float) -> void:
	follow_mouse(delta)
	rotate_velocity(delta)
	handle_shadow(delta)
	shadow.visible = following_mouse or is_played
	
func rotate_velocity(delta: float) -> void:
	if not following_mouse: return
	# Compute the velocity
	velocity = (position - last_pos) / maxf(delta, 0.0001)
	last_pos = position
	
	oscillator_velocity += velocity.normalized().x * velocity_multiplier
	
	# Oscillator stuff
	var force = -spring * displacement - damp * oscillator_velocity
	oscillator_velocity += force * delta
	displacement += oscillator_velocity * delta
	
	rotation = displacement

func handle_shadow(delta: float) -> void:
	# Y position is enver changed.
	# Only x changes depending on how far we are from the center of the screen
	var center: Vector2 = get_viewport_rect().size / 2.0
	var distance: float = global_position.x - center.x
	
	shadow.position.x = lerp(0.0, -sign(distance) * max_offset_shadow, abs(distance/(center.x)))

func follow_mouse(delta: float) -> void:
	if not following_mouse: return
	var mouse_pos: Vector2 = get_global_mouse_position()
	global_position = mouse_pos - (size/2.0)
	drag_moved.emit(self)

func handle_mouse_click(event: InputEvent) -> void:
	if is_played or is_dealing: return
	if not event is InputEventMouseButton: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	
	if event.is_pressed():
		if following_mouse:
			return
		if tween_handle and tween_handle.is_running():
			tween_handle.kill()
		following_mouse = true
		drag_cancelled = false
		_animate_scale(Vector2.ONE)
		last_pos = position
		displacement = 0.0
		oscillator_velocity = 0.0
		resting_z_index = z_index
		z_index = 100
		drag_started.emit(self)
	else:
		_finish_drag()

func _input(event: InputEvent) -> void:
	# Release also works outside the card's GUI rectangle.
	if following_mouse and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			follow_mouse(0.0)
			_finish_drag()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and following_mouse:
		_finish_drag(true)

func _finish_drag(cancelled: bool = false) -> void:
	if not following_mouse:
		return
	following_mouse = false
	drag_cancelled = cancelled
	z_index = resting_z_index
	drag_ended.emit(self)
	if tween_handle and tween_handle.is_running():
		tween_handle.kill()
	# The hand restores its own slightly fanned resting angle.
	if not drag_ended.has_connections():
		tween_handle = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween_handle.tween_property(self, "rotation", 0.0, 0.3)
	_on_mouse_exited()

func _on_gui_input(event: InputEvent) -> void:
	if is_played or is_dealing: return
	
	handle_mouse_click(event)
	
	# Don't compute rotation when moving the card
	if following_mouse: return
	if not event is InputEventMouseMotion: return
	
	# Handles rotation
	# Get local mouse pos
	var mouse_pos: Vector2 = get_local_mouse_position()
	#print("Mouse: ", mouse_pos)
	#print("Card: ", position + size)
	var diff: Vector2 = (position + size) - mouse_pos

	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0, 1)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0, 1)
	#print("Lerp val x: ", lerp_val_x)
	#print("lerp val y: ", lerp_val_y)

	var rot_x: float = rad_to_deg(lerp_angle(-angle_x_max, angle_x_max, lerp_val_x))
	var rot_y: float = rad_to_deg(lerp_angle(angle_y_max, -angle_y_max, lerp_val_y))
	#print("Rot x: ", rot_x)
	#print("Rot y: ", rot_y)
	
	card_texture.material.set_shader_parameter("x_rot", rot_y)
	card_texture.material.set_shader_parameter("y_rot", rot_x)

func _on_mouse_entered() -> void:
	if following_mouse or is_played or is_dealing: return
	if not disabled:
		ButtonAudio.play(self, ButtonAudio.HOVER, -4.0)
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)

func _on_mouse_exited() -> void:
	if is_dealing: return
	# Reset rotation
	if tween_rot and tween_rot.is_running():
		tween_rot.kill()
	tween_rot = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK).set_parallel(true)
	tween_rot.tween_property(card_texture.material, "shader_parameter/x_rot", 0.0, 0.5)
	tween_rot.tween_property(card_texture.material, "shader_parameter/y_rot", 0.0, 0.5)
	
	# Keep the play preview stable even when rotation triggers mouse exit.
	var target_scale := played_scale if is_played else (0.95 if play_preview else 1.0)
	_animate_scale(Vector2.ONE * target_scale)

func set_play_preview(active: bool) -> void:
	if play_preview == active:
		return
	play_preview = active
	_animate_scale(Vector2.ONE * (0.95 if active else 1.0))

func _animate_scale(target: Vector2) -> void:
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_hover.tween_property(self, "scale", target, 0.15)
