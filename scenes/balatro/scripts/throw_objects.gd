extends Control

const COOLDOWN := 8.0
const SHORT_THROW_DISTANCE := 700.0
const FULL_SPEED_THROW_DISTANCE := 1800.0
const MAX_THROW_SPEED_MULTIPLIER := 1.8
const FAST_THROW = preload("res://scenes/balatro/audio/fast-throw.mp3")
const LONG_THROW = preload("res://scenes/balatro/audio/long-throw.mp3")
const GameAudio = preload("res://scenes/balatro/scripts/game_audio.gd")
const Catalog = preload("res://scenes/balatro/scripts/throw_catalog.gd")
var textures: Array[Texture2D] = []
var items: Array[TextureRect] = []
var selected := 0
var equipped: Array = [0, 1, -1]
const SLOT_RADIUS := 110.0
const SLOT_ANGLES := [-60.0, -10.0, 40.0]
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
var host: Control
var menu_button: Button
var item: TextureRect
var poop: Texture2D
var dragging := false
var opened := false
var remaining := 0.0
var motion: Tween
var slots: Array[Panel] = []
var drag_origin := Vector2.ZERO

func setup(controller: Control) -> void:
	host = controller
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 210
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	poop = _svg("res://scenes/balatro/resources/poop.svg")
	equipped = get_node("/root/GameSettings").values.throw_slots.duplicate()
	for filename in Catalog.FILES:
		var path: String = "res://scenes/balatro/resources/" + filename
		textures.append(load(path) as Texture2D if not filename.is_empty() and ResourceLoader.exists(path) else null)
	menu_button = RoundedSquareButton.new()
	add_child(menu_button)
	menu_button.size = Vector2(60, 60)
	menu_button.expand_icon = true
	menu_button.icon = _svg("res://scenes/balatro/trick_asset/ui_bisca/message.svg")
	menu_button.add_theme_constant_override("icon_max_width", 36)
	menu_button.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := Style.button_style(Style.HOVER if state in ["hover", "focus"] else Style.NORMAL)
		style.set_corner_radius_all(30)
		menu_button.add_theme_stylebox_override(state, style)
	menu_button.pressed.connect(func(): _open(not opened))
	for index in range(3):
		var slot := Panel.new()
		slot.size = Vector2(76, 76)
		slot.pivot_offset = slot.size / 2
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := Style.button_style(Style.NORMAL if Catalog.enabled(equipped[index]) else Style.DISABLED)
		style.set_corner_radius_all(38)
		slot.add_theme_stylebox_override("panel", style)
		add_child(slot)
		slot.hide()
		slots.append(slot)
	for index in range(3):
		var object_id: int = equipped[index]
		var icon := _image(object_id)
		items.append(icon)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP if Catalog.enabled(object_id) else Control.MOUSE_FILTER_IGNORE
		icon.hide()
		icon.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and remaining <= 0 and Catalog.enabled(equipped[index]):
				if motion and motion.is_valid(): motion.kill()
				selected = equipped[index]
				item = icon
				dragging = true
				drag_origin = item.position
				item.scale = Vector2.ONE
				item.accept_event()
		)
	item = items[0]
	get_node("/root/NetworkSession").object_thrown.connect(_received)
	get_node("/root/GameSettings").changed.connect(_refresh_equipped)
	_refresh_equipped()

func _refresh_equipped() -> void:
	var show_objects: bool = get_node("/root/GameSettings").values.show_thrown_objects
	visible = show_objects
	if not show_objects:
		dragging = false
		opened = false
		for icon in items: icon.hide()
		for slot in slots: slot.hide()
		for child in get_children():
			if child.has_meta("throw_effect"):
				child.queue_free()
	var next: Array = get_node("/root/GameSettings").values.throw_slots
	if equipped == next:
		return
	equipped = next.duplicate()
	dragging = false
	for index in items.size():
		var id: int = equipped[index]
		items[index].texture = textures[id] if Catalog.enabled(id) else null
		items[index].mouse_filter = Control.MOUSE_FILTER_STOP if Catalog.enabled(id) else Control.MOUSE_FILTER_IGNORE
		items[index].visible = opened and Catalog.enabled(id)
		var style := Style.button_style(Style.NORMAL if Catalog.enabled(id) else Style.DISABLED)
		style.set_corner_radius_all(38)
		slots[index].add_theme_stylebox_override("panel", style)

func _svg(path: String) -> Texture2D:
	return load(path) as Texture2D

func _image(object_id := 0) -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = textures[object_id] if object_id >= 0 and object_id < textures.size() else null
	image.size = Vector2(64, 64)
	image.pivot_offset = image.size / 2
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(image)
	return image

func _point(badge: Control, point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * (badge.get_global_transform_with_canvas() * point)

func _slot_position(index: int) -> Vector2:
	var center := menu_button.position + menu_button.size / 2.0
	return center + Vector2.RIGHT.rotated(deg_to_rad(SLOT_ANGLES[index])) * SLOT_RADIUS - Vector2(38, 38)

func _object_position(index: int, object_size: Vector2) -> Vector2:
	var slot_center := _slot_position(index) + Vector2(38, 38)
	return slot_center - object_size / 2.0

func _process(delta: float) -> void:
	remaining = maxf(0, remaining - delta)
	if host == null or host.scores.get_child_count() == 0:
		return
	var own: Control = host.scores.get_child(0)
	menu_button.visible = own.is_visible_in_tree()
	# Keep the menu and its slots at the table seat while badges move to center.
	if not host.damage_shade.visible:
		menu_button.position = _point(own, Vector2(155, 65))
	menu_button.disabled = remaining > 0
	menu_button.tooltip_text = "Ricarica: %ds" % ceili(remaining) if remaining > 0 else "Lancia un oggetto"
	if not is_visible_in_tree() or not menu_button.visible:
		dragging = false
		opened = false
		for icon in items: icon.hide()
		for slot in slots: slot.hide()
	for index in range(slots.size()):
		slots[index].position = _slot_position(index)
	if dragging:
		item.position = get_local_mouse_position() - item.size / 2
	elif opened:
		for index in range(items.size()): items[index].position = _object_position(index, items[index].size)

func _open(value: bool) -> void:
	opened = value
	if motion and motion.is_valid(): motion.kill()
	motion = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT if value else Tween.EASE_IN)
	for index in range(items.size()):
		var icon := items[index]
		icon.visible = Catalog.enabled(equipped[index])
		icon.position = _object_position(index, icon.size)
		icon.scale = Vector2.ONE * (0.5 if value else 1.0)
		motion.tween_property(icon, "scale", Vector2.ONE if value else Vector2.ONE * 0.5, 0.28 if value else 0.18)
	for index in range(slots.size()):
		var slot := slots[index]
		slot.position = _slot_position(index)
		slot.show()
		slot.scale = Vector2.ONE * (0.5 if value else 1.0)
		motion.parallel().tween_property(slot, "scale", Vector2.ONE if value else Vector2.ONE * 0.5, 0.28 if value else 0.18)
	if not value:
		motion.chain().tween_callback(func():
			for icon in items: icon.hide()
			for slot in slots: slot.hide()
		)

func _input(event: InputEvent) -> void:
	if not dragging or not is_visible_in_tree(): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging = false
		var target := -1
		for index in range(1, host.scores.get_child_count()):
			var badge: Control = host.scores.get_child(index)
			if badge.is_visible_in_tree() and badge.get_local_mouse_position().distance_to(Vector2(80, 128)) <= 70:
				target = index
				break
		if target >= 0 and remaining <= 0:
			remaining = COOLDOWN
			opened = false
			for icon in items: icon.hide()
			for slot in slots: slot.hide()
			# Locally launch from the selected object's original slot, not the drop.
			_launch(0, target, drag_origin, selected)
			if host.online:
				var count: int = host.scores.get_child_count()
				get_node("/root/NetworkSession").send({"op": "throw", "target": (target + host.online_match.local_id) % count, "object_id": selected})
		else:
			_open(true)
		get_viewport().set_input_as_handled()

func _received(sender: int, target: int, object_id := 0) -> void:
	if not host.online or not is_visible_in_tree(): return
	# Our own flight already started on release; don't play it twice.
	if sender == host.online_match.local_id: return
	var count: int = host.scores.get_child_count()
	if count == 0: return
	_launch(host.online_match.seat(sender, count), host.online_match.seat(target, count), Vector2.INF, object_id)

func _launch(sender: int, target: int, local_origin := Vector2.INF, object_id := 0) -> void:
	if not get_node("/root/GameSettings").values.show_thrown_objects: return
	if sender < 0 or target < 0 or maxi(sender, target) >= host.scores.get_child_count(): return
	if object_id < 0 or object_id >= textures.size() or textures[object_id] == null: return
	var projectile := _image(object_id)
	projectile.set_meta("throw_effect", true)
	var origin := _point(host.scores.get_child(sender), Vector2(80, 128)) - projectile.size / 2
	if local_origin != Vector2.INF:
		origin = local_origin
	var destination := _point(host.scores.get_child(target), Vector2(80, 128)) - projectile.size / 2
	# Set the initial position before the first rendered frame.
	projectile.position = origin
	var distance := origin.distance_to(destination)
	var sound: AudioStream = FAST_THROW if distance <= SHORT_THROW_DISTANCE else LONG_THROW
	var impact_sound: AudioStream = Catalog.impact_sound(object_id)
	var distance_ratio := clampf((distance - SHORT_THROW_DISTANCE) / (FULL_SPEED_THROW_DISTANCE - SHORT_THROW_DISTANCE), 0.0, 1.0)
	var speed_multiplier := lerpf(1.0, MAX_THROW_SPEED_MULTIPLIER, distance_ratio)
	var flight_duration := maxf(sound.get_length(), 0.1) / speed_multiplier
	# Each projectile owns its flight sound, including simultaneous throws.
	var flight_audio := AudioStreamPlayer.new()
	flight_audio.stream = sound
	# Accorcia anche il suono di volo, così termina insieme all'impatto.
	flight_audio.pitch_scale = speed_multiplier
	get_node("/root/GameSettings").configure_sfx(flight_audio, -10.0)
	projectile.add_child(flight_audio)
	flight_audio.play()
	var flight := projectile.create_tween()
	flight.tween_method(func(progress: float):
		projectile.position = origin.lerp(destination, progress) + Vector2(0, -120 * sin(progress * PI))
		projectile.rotation = progress * TAU
	, 0.0, 1.0, flight_duration)
	flight.tween_callback(func():
		flight_audio.stop()
		GameAudio.play(projectile, impact_sound, -10.0)
	)
	flight.tween_property(projectile, "scale", Vector2(1.3, 0.8), 0.12)
	flight.tween_property(projectile, "scale", Vector2.ONE, 0.15)
	flight.tween_interval(0.6)
	flight.tween_property(projectile, "modulate:a", 0.0, 0.25)
	flight.tween_callback(projectile.queue_free)
