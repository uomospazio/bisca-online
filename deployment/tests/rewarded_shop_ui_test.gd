extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1920, 1080)
	var manager := root.get_node("ShopManager")
	manager.catalog_ready = true
	manager.inventory_ready = true
	manager._daily_until = Time.get_ticks_msec() + 60000
	manager.daily_refresh_available = true
	manager._daily_ids = ["deck_back_2", "deck_back_3", "deck_back_4"]
	for index in range(2, 5):
		var id := "deck_back_%d" % index
		manager._catalog[id] = {"id": id, "name": "Dorso %d" % index, "item_type": "deck_back", "price": 100, "rarity": "common", "is_available": true, "is_default": false, "asset_id": index}
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	menu._show_shop()
	await create_timer(0.7).timeout
	var page: Control = menu.shop_page
	assert(page.grid.get_child_count() == 3)
	assert(page.fixed_controls.size() == 4)
	for offer in page.fixed_controls.slice(2):
		assert(offer.size.x >= 350)
		assert(offer.position.y + offer.size.y <= 1080)
		assert(offer.button.disabled, "No real ads on desktop")
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/bisca-admob-shop.png")
	print("PASS: three shop offers, ad controls fit, no desktop rewards")
	menu.queue_free()
	await process_frame
	quit()
