extends SceneTree

class Account extends Node:
	var user_id := "ui-test"
	func is_authenticated() -> bool: return true

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var account := Account.new()
	root.add_child(account)
	var manager := root.get_node("ShopManager")
	manager._account = account
	manager._owner = account.user_id
	manager.catalog_ready = true
	manager.inventory_ready = true
	manager._daily_ids = ["deck_back_2", "deck_back_3", "deck_back_4", "deck_back_5", "deck_back_6", "deck_back_7"]
	for index in range(1, 13):
		var id := "deck_back_%d" % index
		manager._catalog[id] = {"id": id, "name": "Dorso %d" % index, "item_type": "deck_back", "price": 0 if index == 1 else 100, "rarity": "common", "is_available": true, "is_default": index == 1, "asset_id": index}
	manager._inventory = {"deck_back_1": {"user_id": account.user_id, "item_id": "deck_back_1"}}
	var settings: Dictionary = root.get_node("GameSettings").values.duplicate(true)
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	menu._show_shop()
	await create_timer(0.6).timeout
	assert(menu.shop_page.is_visible_in_tree())
	assert(menu.shop_page.grid.get_child_count() == 6)
	assert(menu.deck_selector.get_parent() == menu.shop_page.content)
	assert(menu.deck_selector.is_visible_in_tree())
	assert(is_equal_approx(menu.shop_page.content.position.y, float(menu.shop_page.scroll_padding.get_theme_constant("margin_top"))))
	assert(is_equal_approx(menu.shop_page.shop_scroll.size.y, root.get_visible_rect().size.y))
	var hud: Control = menu.shop_page.fixed_controls[0]
	var hud_position := hud.global_position
	var before_scroll: Vector2 = menu.shop_page.content.global_position
	menu.shop_page.shop_scroll.scroll_vertical = 200
	await process_frame
	await process_frame
	assert(menu.shop_page.content.global_position.y < before_scroll.y)
	assert(hud.global_position == hud_position)
	assert(menu.shop_page._item_at_position(hud.get_global_transform_with_canvas() * (hud.size / 2.0)) == "")
	menu.shop_page.shop_scroll.scroll_vertical = 0
	assert(menu.shop_page.shop_scroll.scroll_vertical == 0)
	assert(not menu.home_persistent_ui.visible)
	assert(not menu.title.visible)
	assert(root.get_node("GameSettings").values == settings)
	var preferences := root.get_node("GameSettings")
	var original_path: String = preferences.save_path
	preferences.save_path = "/private/tmp/bisca-deck-edit-toggle.cfg"
	var deck: Control = menu.deck_selector
	assert(deck.editing_controls.size() == 3)
	deck.edit_button.pressed.emit()
	await create_timer(0.4).timeout
	assert(deck.editing and deck.edit_button.visible and not deck.switching)
	deck._flip()
	await create_timer(0.4).timeout
	deck._cycle(1)
	var chosen_front: int = deck.selected_front
	deck.edit_button.pressed.emit()
	await create_timer(0.7).timeout
	assert(not deck.editing and deck.edit_button.visible and not deck.showing_front)
	assert(preferences.values.deck_front == chosen_front)
	for control in deck.editing_controls:
		assert(not control.visible)
	preferences.save_timer.stop()
	preferences.values = settings.duplicate(true)
	preferences.save_path = original_path
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/bisca-market-top.png")
		menu.shop_page.shop_scroll.scroll_vertical = 780
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/bisca-market-bottom.png")
	menu.show_home()
	await create_timer(1.0).timeout
	assert(not menu.shop_page.visible)
	assert(menu.home_persistent_ui.visible)
	assert(not menu.deck_selector.is_visible_in_tree())
	menu._show_shop()
	await create_timer(0.6).timeout
	assert(menu.shop_page.grid.get_child_count() == 6)
	assert(menu.shop_page.shop_scroll.scroll_vertical == 0)
	assert(root.get_node("GameSettings")._valid_throw_slots([999, 1, -1]) == [-1, 1, -1])
	menu.free()
	manager._account = null
	account.free()
	print("PASS Shop UI: 6 offerte, selettore solo nello shop, ritorno HOME e preferenze invariate")
	quit()
