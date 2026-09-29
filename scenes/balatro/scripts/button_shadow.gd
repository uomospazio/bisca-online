class_name ButtonShadow
extends Control

const SHADOW_COLOR := Color("241f1d")
const SHADOW_OFFSET := Vector2(5, 5)

var target: Control
var corner_radius := 0

func setup(owner_control: Control, radius: int = -1) -> void:
	target = owner_control
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	show_behind_parent = true

	# Se viene passato un radius esplicito lo mantiene.
	# Altrimenti segue automaticamente Y/2 del pulsante.
	corner_radius = radius if radius >= 0 else int(target.size.y / 2.0)

	if not target.resized.is_connected(_sync_to_target):
		target.resized.connect(_sync_to_target)

	_sync_to_target()
	queue_redraw()

func _sync_to_target() -> void:
	if not is_instance_valid(target):
		return

	size = target.size
	position = SHADOW_OFFSET

	# Radius sempre pari a metà dell'altezza del target.
	corner_radius = int(target.size.y / 2.0)

	queue_redraw()

func _draw() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = SHADOW_COLOR
	style.set_corner_radius_all(corner_radius)
	draw_style_box(style, Rect2(Vector2.ZERO, size))
