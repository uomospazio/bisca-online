extends SceneTree
const Page = preload("res://scenes/balatro/scripts/assistant_chat.gd")
func _initialize() -> void: run.call_deferred()
func run() -> void:
	create_timer(15).timeout.connect(func(): quit(1))
	var host := Control.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var page = Page.open(host)
	await process_frame
	await process_frame
	assert(not paused)
	assert(page.question_buttons.size() == page.topics.size())
	assert(page.content.get_child_count() == 10)
	assert(not page.back_button.visible)
	assert(page.find_children("*", "LineEdit", true, false).is_empty())
	for child in page.get_children(): assert(not child is ColorRect)
	assert(Page.display_text("Perché è così?") == "Perche' e' cosi'?")
	for dimensions in [Vector2(1920, 1080), Vector2(1280, 720), Vector2(844, 390), Vector2(667, 375)]:
		var bounds := Rect2(Vector2(20, 10), dimensions)
		page.layout_in(bounds)
		await process_frame
		assert(bounds.encloses(Rect2(page.panel.position, page.panel.size * page.panel.scale)))
		for card in page.question_buttons:
			var material: ShaderMaterial = card.get_meta("generic_ui_material")
			assert(material.get_shader_parameter("fill_top") == Color("1D1A48"))
			assert(material.get_shader_parameter("fill_bottom") == Color("1D1A48"))
			assert(material.get_shader_parameter("corner_radius") == 10.0)
			assert(not material.get_shader_parameter("pill_highlight"))
	for topic in page.topics:
		for locale in ["it", "en"]:
			assert(topic[locale].answer.split("\n\n").size() >= 3)
		page._show_answer(topic.id)
		assert(page.selected_topic == topic.id)
		assert(page.content.get_node("Answer").text == Page.display_text(topic[page.language].answer))
		assert(page.back_button.visible)
		assert(page.content.get_node("Answer").get_theme_constant("line_spacing") == 8)
		page.back_button.pressed.emit()
		assert(page.selected_topic.is_empty())
		assert(page.question_buttons.size() == page.topics.size())
	page.question_buttons[0].pressed.emit()
	assert(page.selected_topic == "goal")
	page._close()
	assert(not page.visible)
	assert(Page.open(host) == page)
	assert(page.selected_topic.is_empty())
	assert(not paused)
	page._fit()
	await process_frame
	if "--snapshot" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-qa.png")
	host.queue_free()
	await process_frame
	print("PASS: Q&A groups, all answers, Back, reopen, no input field, layouts, no pause")
	quit()
