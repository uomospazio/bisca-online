extends RefCounted

# Only peripheral controls use this helper. The table and characters keep
# their centered 1920x1080 coordinates. No per-frame layout or polling.
static func attach(control: Control, right: bool = false) -> void:
	if control.get_parent() is Container or control.has_meta("safe_edge"):
		return
	control.set_meta("safe_edge", Vector2.ZERO)
	var update := func():
		if not is_instance_valid(control):
			return
		var viewport_size := control.get_viewport_rect().size
		var safe := Rect2(Vector2.ZERO, viewport_size)
		if OS.has_feature("web"):
			# Browser CSS pixels must be converted to logical Godot coordinates.
			# Older/custom shells without the bridge retain the full viewport.
			var encoded = JavaScriptBridge.eval("typeof window.biscaSafeArea === 'function' ? window.biscaSafeArea() : '[0,0,1,1]'", true)
			var fractions = JSON.parse_string(str(encoded))
			if fractions is Array and fractions.size() == 4:
				safe = Rect2(Vector2(float(fractions[0]), float(fractions[1])) * viewport_size, Vector2(float(fractions[2]), float(fractions[3])) * viewport_size)
		elif OS.has_feature("mobile"):
			var window := control.get_window()
			var physical := Rect2(DisplayServer.get_display_safe_area())
			physical = physical.intersection(Rect2(Vector2(window.position), Vector2(window.size)))
			if physical.has_area():
				var ratio := viewport_size / Vector2(window.size)
				safe = Rect2((physical.position - Vector2(window.position)) * ratio, physical.size * ratio)
		var origin := (viewport_size - Vector2(1920, 1080)) * 0.5
		var delta := Vector2(safe.end.x - viewport_size.x + origin.x if right else safe.position.x - origin.x, safe.position.y - origin.y)
		var previous: Vector2 = control.get_meta("safe_edge")
		control.position += delta - previous
		control.set_meta("safe_edge", delta)
	control.get_viewport().size_changed.connect(update, CONNECT_DEFERRED)
	control.tree_exiting.connect(func():
		if control.get_viewport().size_changed.is_connected(update):
			control.get_viewport().size_changed.disconnect(update)
	, CONNECT_ONE_SHOT)
	update.call_deferred()
