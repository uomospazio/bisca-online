extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var area := preload("res://scenes/balatro/scripts/play_area.gd").new()
	root.add_child(area)
	var card := Control.new()
	card.size = Vector2(120, 180)
	area.add_child(card)
	area.position = Vector2(-573, -229)
	area.size = Vector2(1146, 466)
	var original: Array[Vector2] = []
	for seat in range(8):
		card.set_meta("seat_id", seat)
		original.append(area.position + area.landing_position(card))
	area.position = Vector2(-480, -186)
	area.size = Vector2(960, 380)
	for seat in range(8):
		card.set_meta("seat_id", seat)
		assert((area.position + area.landing_position(card)).is_equal_approx(original[seat]))
	area.queue_free()
	await process_frame
	print("PASS: all eight card landing positions unchanged after play area resize")
	quit()
