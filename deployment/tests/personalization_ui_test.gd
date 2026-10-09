extends SceneTree

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	menu._show_personalization()
	var page = menu.personalization_page
	assert(page.deck_selector.get_parent() == page.customization_group)
	assert(page.panel.texture != null)
	assert(is_equal_approx(page.hero.size.x / page.hero.size.y, page.HERO_RECT.size.x / page.HERO_RECT.size.y))
	assert(not menu.profile_button.visible and not menu.name_input.visible)
	assert(page.profile_art.texture != null)
	page.profile_name.text = "TEST"
	page.profile_name.text_changed.emit("TEST")
	assert(menu.name_input.text == "TEST")
	assert(page.customization_group.scale.length() < 0.001)
	assert(page.hero.position == page.HERO_RECT.position and page.hero.size == page.HERO_RECT.size)
	assert(page.hero.modulate.a == 1.0)
	await create_timer(0.25).timeout
	assert(page.profile_art.scale.length() > 0.1)
	for control in page._intro_contents():
		assert(control.scale.is_equal_approx(Vector2.ONE))
	await create_timer(0.20).timeout
	assert(page.deck_selector.front_preview.scale.length() > 0.001)
	assert(page.deck_selector.back_preview.scale.is_equal_approx(Vector2.ONE))
	await create_timer(1.1).timeout
	for control in page._intro_contents():
		assert(control.scale.is_equal_approx(Vector2.ONE))
	assert(page.deck_selector.scale.is_equal_approx(Vector2.ONE))
	assert(page.throw_selector.buttons.size() == 3)
	assert(page.throw_selector.buttons[0].get_theme_stylebox("normal") is StyleBoxTexture)
	for bounds in [Rect2(40,40,1840,1000), Rect2(100,40,2200,900), Rect2(40,40,1200,640)]:
		page._layout(bounds)
		assert((page.composition.position + page.PAGE_SIZE * page.composition.scale / 2).distance_to(bounds.get_center()) < 0.01)
	if "--snapshot" in OS.get_cmdline_user_args():
		for child in menu.get_children():
			if child is CanvasItem and child != page: child.hide()
		var bg := ColorRect.new()
		bg.color = Color("1e1833")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		menu.add_child(bg)
		menu.move_child(bg, 0)
		page._fit()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-personalization-preview.png")
	page.back_button.pressed.emit()
	assert(not menu.shop_character.visible)
	assert(not page.visible)
	await create_timer(0.5).timeout
	menu._show_personalization()
	await create_timer(1.9).timeout
	assert(page.deck_selector.scale.is_equal_approx(Vector2.ONE))
	print("PASS: personalization layout, panel-first pops, selectors and reopen")
	menu.queue_free()
	await process_frame
	quit()
