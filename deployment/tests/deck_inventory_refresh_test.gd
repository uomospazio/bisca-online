extends SceneTree

class TestShop extends Node:
	signal changed
	var loading := false
	var inventory_ready := false
	var stale := false
	var last_error := ""
	var requests := 0
	var items: Array = []
	func refresh() -> void:
		requests += 1
		loading = true
		changed.emit()
	func get_owned_items() -> Array: return items

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var real_shop := root.get_node("ShopManager")
	root.remove_child(real_shop)
	var shop := TestShop.new()
	shop.name = "ShopManager"
	root.add_child(shop)
	var settings := root.get_node("GameSettings")
	settings.save_path = "/private/tmp/bisca-deck-inventory-test.cfg"
	settings.values.deck_back = 7
	var selector = preload("res://scenes/balatro/scripts/deck_selector.gd").new()
	root.add_child(selector)
	assert(shop.requests == 1)
	selector.reset_preview()
	assert(shop.requests == 1) # No duplicate request while loading.
	shop.items = [{"id":"deck_back_1", "asset_id":1}]
	shop.changed.emit()
	assert(selector.selected_back == 1)
	assert(settings.values.deck_back == 7) # Fallback is visual only.
	shop.items.append({"id":"deck_back_7", "asset_id":7})
	shop.loading = false
	shop.inventory_ready = true
	shop.changed.emit()
	assert(selector.selected_back == 7) # Async inventory restores equipped back.
	selector._cycle_back()
	assert(selector.selected_back == 1 and settings.values.deck_back == 1)
	selector._cycle_back()
	assert(selector.selected_back == 7)
	shop.changed.emit()
	assert(selector.selected_back == 7)
	shop.last_error = "Network error"
	selector.reset_preview()
	assert(shop.requests == 2) # Reopening retries, without visiting market.
	shop.items.clear()
	shop.inventory_ready = false
	shop.changed.emit()
	assert(selector.selected_back == 0) # Old account's inventory is not retained.
	selector.free()
	shop.free()
	root.add_child(real_shop)
	print("PASS: inventory retry, no duplicate loading, async saved back, owned cycling, identity reset")
	quit()
