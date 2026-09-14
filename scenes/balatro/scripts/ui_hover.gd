class_name UIHover
extends RefCounted

static func attach(control: Control, hover_scale: float = 1.2) -> void:
	control.pivot_offset = control.size / 2.0
	control.resized.connect(func():
		if is_instance_valid(control):
			control.pivot_offset = control.size / 2.0
	)
	control.mouse_entered.connect(_on_mouse_entered.bind(control, hover_scale))
	control.mouse_exited.connect(_on_mouse_exited.bind(control))

static func _on_mouse_entered(control: Control, hover_scale: float) -> void:
	if not is_instance_valid(control) or control is Button and control.disabled:
		return
	control.pivot_offset = control.size / 2.0
	var tween := control.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(control, "scale:x", hover_scale, 0.2)
	tween.tween_property(control, "scale:y", hover_scale, 0.35)
	tween.tween_property(control, "rotation_degrees", 5.0 * [-1.0, 1.0].pick_random(), 0.1)
	tween.tween_property(control, "rotation_degrees", 0.0, 0.1).set_delay(0.1)

static func _on_mouse_exited(control: Control) -> void:
	if not is_instance_valid(control):
		return
	var tween := control.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(control, "scale:x", 1.0, 0.25)
	tween.tween_property(control, "scale:y", 1.0, 0.35)
	tween.tween_property(control, "rotation_degrees", 0.0, 0.1)
