extends Control

# Decorative highlight only: never intercepts the button's input.
@export var gloss_color := Color("f3effe")
@export var corner_radius := -1.0
@export var pos_scale := Vector2(0.98, 0.94)
@export var max_width := 9.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Redraw on resize, without running a size check every frame.
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if size.y < 30:
		return
	var cr := minf(corner_radius if corner_radius > 0.0 else size.y * 0.5, size.y * 0.5)
	var radius := cr * 0.52
	var width := clampf(cr * 0.16, 4.0, max_width)
	var center := Vector2(cr * pos_scale.x, cr * pos_scale.y)
	draw_colored_polygon(_capsule_arc(center, radius, width, PI * 1.02, PI * 1.42), gloss_color)

func _capsule_arc(center: Vector2, radius: float, width: float, a0: float, a1: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var outer := radius + width * 0.5
	var inner := radius - width * 0.5
	var steps := 22
	for i in range(steps + 1):
		var angle := lerpf(a0, a1, float(i) / steps)
		points.append(center + Vector2(cos(angle), sin(angle)) * outer)
	var end := center + Vector2(cos(a1), sin(a1)) * radius
	for i in range(1, 8):
		var angle := a1 + PI * float(i) / 8.0
		points.append(end + Vector2(cos(angle), sin(angle)) * width * 0.5)
	for i in range(steps + 1):
		var angle := lerpf(a1, a0, float(i) / steps)
		points.append(center + Vector2(cos(angle), sin(angle)) * inner)
	var start := center + Vector2(cos(a0), sin(a0)) * radius
	for i in range(1, 8):
		var angle := a0 + PI + PI * float(i) / 8.0
		points.append(start + Vector2(cos(angle), sin(angle)) * width * 0.5)
	return points
