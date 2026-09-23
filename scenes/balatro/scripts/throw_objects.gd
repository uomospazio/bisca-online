extends Control

const COOLDOWN := 8.0
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
var host: Control
var menu_button: Button
var item: TextureRect
var poop: Texture2D
var dragging := false
var opened := false
var remaining := 0.0
var motion: Tween

func setup(controller: Control) -> void:
	host = controller
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 210
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	poop = _svg("res://scenes/balatro/resources/poop.svg")
	menu_button = RoundedSquareButton.new()
	add_child(menu_button)
	menu_button.size = Vector2(44, 44)
	menu_button.expand_icon = true
	menu_button.icon = _svg("res://scenes/balatro/trick_asset/ui_bisca/message.svg")
	menu_button.add_theme_constant_override("icon_max_width", 26)
	menu_button.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := Style.button_style(Style.HOVER if state in ["hover", "focus"] else Style.NORMAL)
		style.set_corner_radius_all(22)
		menu_button.add_theme_stylebox_override(state, style)
	menu_button.pressed.connect(func(): _open(not opened))
	item = _image()
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.hide()
	item.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and remaining <= 0:
			if motion and motion.is_valid(): motion.kill()
			dragging = true
			item.scale = Vector2.ONE
			item.accept_event()
	)
	get_node("/root/NetworkSession").object_thrown.connect(_received)

func _svg(path: String) -> Texture2D:
	return load(path) as Texture2D

func _image() -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = poop
	image.size = Vector2(64, 64)
	image.pivot_offset = image.size / 2
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(image)
	return image

func _point(badge: Control, point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * (badge.get_global_transform_with_canvas() * point)

func _process(delta: float) -> void:
	remaining = maxf(0, remaining - delta)
	if host == null or host.scores.get_child_count() == 0:
		return
	var own: Control = host.scores.get_child(0)
	menu_button.visible = own.is_visible_in_tree() and not own.eliminated
	menu_button.position = _point(own, Vector2(155, 65))
	menu_button.disabled = remaining > 0
	menu_button.tooltip_text = "Ricarica: %ds" % ceili(remaining) if remaining > 0 else "Lancia un oggetto"
	if not is_visible_in_tree() or not menu_button.visible:
		dragging = false
		opened = false
		item.hide()
	if dragging:
		item.position = get_local_mouse_position() - item.size / 2
	elif opened:
		item.position = menu_button.position + Vector2(52, -10)

func _open(value: bool) -> void:
	opened = value
	if motion and motion.is_valid(): motion.kill()
	item.show()
	item.position = menu_button.position + Vector2(52, -10)
	item.scale = Vector2.ONE * (0.5 if value else 1.0)
	motion = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT if value else Tween.EASE_IN)
	motion.tween_property(item, "scale", Vector2.ONE if value else Vector2.ONE * 0.5, 0.28 if value else 0.18)
	if not value: motion.tween_callback(item.hide)

func _input(event: InputEvent) -> void:
	if not dragging or not is_visible_in_tree(): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
		var target := -1
		for index in range(1, host.scores.get_child_count()):
			var badge: Control = host.scores.get_child(index)
			if badge.is_visible_in_tree() and not badge.eliminated and badge.get_local_mouse_position().distance_to(Vector2(80, 128)) <= 70:
				target = index
				break
		if target >= 0 and remaining <= 0:
			remaining = COOLDOWN
			opened = false
			item.hide()
			# The dragged icon only selects the recipient. Start a fresh flight
			# from our profile immediately, without waiting for the server echo.
			_launch(0, target)
			if host.online:
				var count: int = host.scores.get_child_count()
				get_node("/root/NetworkSession").send({"op": "throw", "target": (target + host.online_match.local_id) % count})
		else:
			_open(true)
		get_viewport().set_input_as_handled()

func _received(sender: int, target: int) -> void:
	if not host.online or not is_visible_in_tree(): return
	# Our own flight already started on release; don't play it twice.
	if sender == host.online_match.local_id: return
	var count: int = host.scores.get_child_count()
	if count == 0: return
	_launch(host.online_match.seat(sender, count), host.online_match.seat(target, count))

func _launch(sender: int, target: int) -> void:
	if sender < 0 or target < 0 or maxi(sender, target) >= host.scores.get_child_count(): return
	var projectile := _image()
	var origin := _point(host.scores.get_child(sender), Vector2(80, 128)) - projectile.size / 2
	var destination := _point(host.scores.get_child(target), Vector2(80, 128)) - projectile.size / 2
	# Set the initial position before the first rendered frame.
	projectile.position = origin
	var flight := create_tween()
	flight.tween_method(func(progress: float):
		projectile.position = origin.lerp(destination, progress) + Vector2(0, -120 * sin(progress * PI))
		projectile.rotation = progress * TAU
	, 0.0, 1.0, 0.65)
	flight.tween_property(projectile, "scale", Vector2(1.3, 0.8), 0.12)
	flight.tween_property(projectile, "scale", Vector2.ONE, 0.15)
	flight.tween_interval(0.6)
	flight.tween_property(projectile, "modulate:a", 0.0, 0.25)
	flight.tween_callback(projectile.queue_free)
