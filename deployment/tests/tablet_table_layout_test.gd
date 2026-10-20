extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1509)
	root.add_child(viewport)
	var match_scene = load("res://scenes/balatro/balatro.tscn").instantiate()
	viewport.add_child(match_scene)
	await process_frame
	for dimensions in [Vector2i(2350,1080), Vector2i(1920,1440), Vector2i(1920,1509)]:
		viewport.size = dimensions
		await process_frame
		match_scene._fit_screen()
		var gameplay = match_scene.game_ui
		assert(gameplay.scale.is_equal_approx(match_scene.get_node("Parallax").scale))
		assert(gameplay.scale.is_equal_approx(match_scene.overlay.scale))
		var transform: Transform2D = gameplay.get_global_transform_with_canvas()
		for seat in match_scene.SEAT_POSITIONS:
			var bounds := transform * Rect2(seat, Vector2(216, 280))
			assert(bounds.position.x >= 0, "Player clipped at left: %s" % dimensions)
			assert(bounds.end.x <= dimensions.x, "Player clipped at right: %s" % dimensions)
			assert(bounds.position.y >= 0 and bounds.end.y <= dimensions.y)
		assert(match_scene.menu.scale == Vector2.ONE, "Menu must not inherit table scaling")
	match_scene.queue_free()
	viewport.queue_free()
	await process_frame
	print("PASS: wide/tablet table composition, all eight seats and unchanged menu scale")
	quit()
