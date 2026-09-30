extends Control

# Geometry from Dub Together's ButtonBevel; redraw only when resized.
var dark := Color(0, 0, 0, 0.26)
var light := Color(1, 1, 1, 0.8)
var corner_radius := -1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if size.y < 26.0 or size.x < size.y:
		return
	if dark.a > 0.0:
		draw_colored_polygon(_crescent(false, clampf(size.y * 0.1, 4.0, 9.0), 4.0), dark)
	if light.a > 0.0:
		draw_colored_polygon(_crescent(true, clampf(size.y * 0.042, 2.0, 4.5), 4.0), light)

func _crescent(top: bool, thick: float, inset: float) -> PackedVector2Array:
	var cr := minf(corner_radius if corner_radius > 0.0 else size.y * 0.5, size.y * 0.5)
	var radius := maxf(cr - inset, 4.0)
	var forward := PackedVector2Array()
	var steps := 12
	var cy := inset + radius if top else size.y - inset - radius
	var left := Vector2(inset + radius, cy)
	var right := Vector2(size.x - inset - radius, cy)
	for i in range(steps + 1):
		var angle := lerpf(PI * 1.1 if top else PI * 0.9, PI * 1.5 if top else PI * 0.5, float(i) / steps)
		forward.append(left + Vector2(cos(angle), sin(angle)) * radius)
	for i in range(steps + 1):
		var angle := lerpf(PI * 1.5 if top else PI * 0.5, PI * 1.9 if top else PI * 0.1, float(i) / steps)
		forward.append(right + Vector2(cos(angle), sin(angle)) * radius)
	var points := forward.duplicate()
	var shift := Vector2(0, thick if top else -thick)
	for i in range(forward.size() - 1, -1, -1):
		points.append(forward[i] + shift)
	return points
