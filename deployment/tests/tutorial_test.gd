extends SceneTree

const Tutorial = preload("res://scenes/balatro/scripts/tutorial_page.gd")
const Flow = preload("res://scenes/balatro/scripts/tutorial_flow.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1800, 900)
	var page := Tutorial.new()
	root.add_child(page)
	await process_frame
	assert(page.table_background.get_rect().size == page.size, "Table must fill the screen, not a tutorial sidebar")
	assert(page.table_background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	var outcomes: Array = []
	page.finished.connect(func(completed): outcomes.append(completed))
	for index in 10:
		assert(page.step == index)
		assert(page.slide.texture != null)
		assert(page.slide.texture.resource_path.ends_with("tutorial%d.png" % (index + 1)))
		assert(page.portrait.texture.resource_path == Tutorial.PORTRAITS[Tutorial.PORTRAIT_ORDER[index]])
		assert(page.find_children("*", "Button", true, false).size() == 1, "Only the next arrow, no skip")
		assert(page.next_button.visible)
		var ratio := page.slide.size.x / page.slide.size.y
		var texture_ratio := page.slide.texture.get_width() / float(page.slide.texture.get_height())
		assert(absf(ratio - texture_ratio) < 0.005, "Artwork must not stretch")
		if "--snapshot" in OS.get_cmdline_user_args(): await snapshot(str(index + 1))
		page.next_button.pressed.emit()
	assert(outcomes == [true])
	page.advance()
	assert(outcomes == [true], "Completion is emitted only once")
	page.queue_free()
	await process_frame
	var flow := Flow.new()
	flow.save_path = "/tmp/bisca-tutorial-test-%s.cfg" % Time.get_ticks_usec()
	root.add_child(flow)
	assert(not Flow.was_offered(flow.save_path))
	flow.start()
	assert(Flow.was_offered(flow.save_path))
	flow.tutorial.finished.emit(false)
	await process_frame
	assert(not is_instance_valid(flow))
	var offered := Flow.new()
	offered.save_path = "/tmp/bisca-tutorial-offer-test-%s.cfg" % Time.get_ticks_usec()
	var path := offered.save_path
	root.add_child(offered)
	offered.offer()
	var dialog := offered.get_child(1)
	assert(dialog.get_cancel_button().text == "SALTA")
	dialog.canceled.emit()
	await process_frame
	assert(not is_instance_valid(offered) and Flow.was_offered(path))
	var complete := Flow.new()
	complete.save_path = path
	root.add_child(complete)
	complete.start()
	complete.tutorial.finished.emit(true)
	await process_frame
	var config := ConfigFile.new()
	config.load(path)
	assert(config.get_value("tutorial", "completed", false))
	print("PASS: ten numbered slides, portraits, proportional artwork, no skip, completion and onboarding persistence")
	quit()

func snapshot(label: String) -> void:
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/bisca-tutorial-" + label + ".png")
