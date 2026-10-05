extends ScrollContainer
## Vertical touch drags also work when they start over buttons or sliders.
var finger := -1
var start := Vector2.ZERO
var start_scroll := 0
var dragging := false
var blocked: Array[BaseButton] = []

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_restore()
		finger = -1
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			if Rect2(Vector2.ZERO, size).has_point(local):
				finger = event.index
				start = local
				start_scroll = scroll_vertical
				dragging = false
		elif not event.pressed and event.index == finger:
			if dragging:
				get_viewport().set_input_as_handled()
			finger = -1
			dragging = false
			_restore.call_deferred()
	elif event is InputEventScreenDrag and event.index == finger:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		var movement: Vector2 = local - start
		if not dragging and absf(movement.y) > 18 and absf(movement.y) > absf(movement.x):
			dragging = true
			_block_buttons(self)
		if dragging:
			scroll_vertical = start_scroll - int(movement.y)
			get_viewport().set_input_as_handled()

func _block_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton and not child.disabled:
			blocked.append(child)
			child.disabled = true
		_block_buttons(child)

func _restore() -> void:
	for button in blocked:
		if is_instance_valid(button):
			button.disabled = false
	blocked.clear()
