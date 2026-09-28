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
	assert(menu.shop_page.grid.get_child_count() == 12)
	assert(not menu.home_persistent_ui.visible)
	assert(not menu.title.visible)
	assert(root.get_node("GameSettings").values == settings)
	menu.show_home()
	await create_timer(1.0).timeout
	assert(not menu.shop_page.visible)
	assert(menu.home_persistent_ui.visible)
	menu._show_shop()
	await create_timer(0.6).timeout
	assert(menu.shop_page.grid.get_child_count() == 12)
	menu.free()
	manager._account = null
	account.free()
	print("PASS Shop UI: 12 dorsi, apertura/ritorno HOME, riapertura e preferenze invariate")
	quit()
