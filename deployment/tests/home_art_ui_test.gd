extends SceneTree

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var menu = preload("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	for child in menu.get_children():
		if child.get_script() == preload("res://scenes/balatro/scripts/welcome_page.gd"): child.hide()
	await create_timer(1.2).timeout
	assert(not menu.title.visible and not menu.friends_subtitle.visible)
	assert(not menu.home_support_button.visible)
	assert(menu.home_art.blocks.size() == 8)
	var single: Button = menu.home_art.blocks[1]
	single.mouse_entered.emit()
	await create_timer(0.35).timeout
	assert(single.scale.x > 1.0)
	single.mouse_exited.emit()
	await create_timer(0.35).timeout
	assert(single.scale.is_equal_approx(Vector2.ONE) and is_zero_approx(single.rotation))
	menu.set_coins_amount(12345)
	assert(menu.home_art.amount.text == "12345")
	if "--snapshot" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-home-art.png")
	menu._show_personalization()
	var page = menu.personalization_page
	assert(not page.hero.visible)
	await create_timer(0.25).timeout
	assert(page.profile_art.scale.x > 0 and page.customization_group.scale.x > 0 and page.hero.visible)
	await create_timer(0.65).timeout
	assert(page.hero.visible and page.customization_group.scale.is_equal_approx(Vector2.ONE))
	menu.show_home()
	await create_timer(1).timeout
	assert(not menu.title.visible and menu.home_art.is_visible_in_tree())
	print("PASS: home artwork, live coins, personalization sequence and return")
	menu.queue_free()
	await process_frame
	quit()
