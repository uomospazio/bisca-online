extends RefCounted
## Shared Shop-style hover for menu artwork buttons; leaves entrance pops alone.
static func attach(button: Control, rest_scale := Callable()) -> void:
	if button.has_meta("menu_button_hover"): return
	button.set_meta("menu_button_hover", true)
	var state := {"tween": null, "active": false}
	var animate := func(active: bool):
		var base: Vector2 = rest_scale.call() if rest_scale.is_valid() else Vector2.ONE
		if active and ((button is BaseButton and button.disabled) or not button.is_visible_in_tree()): return
		if active and not state.active and not button.scale.is_equal_approx(base): return
		if not active and not state.active: return
		state.active = active
		if state.tween and state.tween.is_valid(): state.tween.kill()
		button.pivot_offset = button.size / 2
		var ratio := clampf(128.0 / maxf(button.size.x, 1), 0.5, 1.0)
		var tween := button.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		state.tween = tween
		tween.tween_property(button, "scale", base * (1 + 0.2 * ratio if active else 1.0), 0.2 if active else 0.25)
		tween.parallel().tween_property(button, "rotation_degrees", 5 * ratio * [-1.0, 1.0].pick_random() if active else 0.0, 0.1)
		if active: tween.tween_property(button, "rotation_degrees", 0.0, 0.1)
	button.mouse_entered.connect(animate.bind(true))
	button.mouse_exited.connect(animate.bind(false))
	button.focus_entered.connect(animate.bind(true))
	button.focus_exited.connect(animate.bind(false))
	button.visibility_changed.connect(func():
		if not button.is_visible_in_tree() and state.active:
			if state.tween and state.tween.is_valid(): state.tween.kill()
			state.active = false
			button.scale = rest_scale.call() if rest_scale.is_valid() else Vector2.ONE
			button.rotation = 0
	)
