extends RefCounted

const GameAudio = preload("res://scenes/balatro/scripts/game_audio.gd")

# Lexispell's simultaneous lateral slide, without freeing reusable menu pages.
static func slide(host: Control, previous: Control, next: Control, backwards := false) -> void:
	if host.has_meta("page_transition_cleanup"):
		host.get_meta("page_transition_cleanup").call()
	if previous == next:
		next.show()
		return
	var end_position := next.position
	var previous_position := previous.position if is_instance_valid(previous) else Vector2.ZERO
	var distance := host.get_viewport_rect().size.x * (-1.0 if backwards else 1.0)
	var layer := CanvasLayer.new()
	layer.layer = 100
	host.add_child(layer)
	var blocker := Control.new()
	layer.add_child(blocker)
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	# Also block keyboard activation during the short transition.
	var old_process := host.process_mode
	host.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := host.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(previous):
		previous.show()
		tween.tween_property(previous, "position:x", previous_position.x - distance, 0.35)
	next.position.x = end_position.x + distance
	next.show()
	tween.tween_property(next, "position:x", end_position.x, 0.35)
	var cleanup := func():
		for connection in tween.finished.get_connections():
			tween.finished.disconnect(connection.callable)
		tween.kill()
		if is_instance_valid(previous):
			previous.hide()
			previous.position = previous_position
		next.position = end_position
		host.process_mode = old_process
		layer.queue_free()
		if host.has_meta("page_transition_cleanup"):
			var callback: Callable = host.get_meta("page_transition_cleanup")
			if host.tree_exiting.is_connected(callback):
				host.tree_exiting.disconnect(callback)
		host.remove_meta("page_transition_cleanup")
	host.set_meta("page_transition_cleanup", cleanup)
	host.tree_exiting.connect(cleanup, CONNECT_ONE_SHOT)
	tween.finished.connect(cleanup)
	GameAudio.play(host, GameAudio.SWIPE, -18.0)
