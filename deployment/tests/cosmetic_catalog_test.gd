extends SceneTree
const Throws = preload("res://scenes/balatro/scripts/throw_catalog.gd")
const Avatars = preload("res://scenes/balatro/scripts/avatar_catalog.gd")
class Account extends Node:
	var user_id := "cosmetics-test"
	func is_authenticated() -> bool: return true

func _initialize() -> void: run.call_deferred()
func run() -> void:
	var settings := root.get_node("GameSettings")
	settings.save_path = "/tmp/bisca-cosmetics-test.cfg"
	settings.values = settings.DEFAULTS.duplicate(true)
	assert(settings.values.throw_slots == [Throws.DEFAULT_INDEX, -1, -1])
	assert(Throws.FILES[Throws.DEFAULT_INDEX] == "pomodoro.png")
	assert(settings.FRONT_FOLDERS.size() == 2)
	for back in [13, 14]:
		settings.set_value("deck_back", back)
		settings.save_preferences()
		settings.load_preferences()
		assert(settings.values.deck_back == back)
		assert(settings.back_texture().resource_path.ends_with("back%d.png" % back))
	settings.set_value("deck_front", 2)
	assert(settings.values.deck_front == 1)
	settings.save_preferences()
	settings.load_preferences()
	assert(settings.values.deck_front == 1)
	for front in 2:
		for suit in 4:
			for rank in range(1,11): assert(settings.front_texture(suit,rank,front) != null)
	for file in Throws.FILES:
		if not file.is_empty(): assert(ResourceLoader.exists("res://scenes/balatro/resources/" + file))
	assert(Avatars.TEXTURES.size() == 32)
	assert(not Avatars.encoded(0).is_empty())
	var manager := root.get_node("ShopManager")
	var account := Account.new()
	root.add_child(account)
	manager._account = account
	manager._owner = account.user_id
	manager.inventory_ready = true
	manager._catalog = {
		"avatar_2": {"id":"avatar_2", "item_type":"avatar", "asset_id":2},
		"throw_poop": {"id":"throw_poop", "item_type":"throwable", "asset_id":0}}
	manager._inventory = {}
	assert(manager.available_assets("avatar") == [1])
	assert(manager.available_assets("throwable") == [8])
	manager._inventory = {"avatar_2": {}, "throw_poop": {}}
	assert(manager.available_assets("avatar") == [1,2])
	assert(manager.available_assets("throwable") == [0,8])
	settings.set_value("throw_slots", [0,1,-1])
	manager._reconcile_throw_slots()
	assert(settings.values.throw_slots == [0,-1,-1])
	account.user_id = "another-account"
	assert(manager.available_assets("avatar") == [1])
	manager._reconcile_throw_slots()
	assert(settings.values.throw_slots == [8,-1,-1])
	var shop = preload("res://scenes/balatro/scripts/shop_page.gd").new()
	root.add_child(shop)
	shop.manager = manager
	shop.grid = Control.new()
	shop.add_child(shop.grid)
	for data in [
		{"id":"deck_back_1","item_type":"deck_back","asset_id":1},
		{"id":"deck_back_13","item_type":"deck_back","asset_id":13},
		{"id":"deck_back_14","item_type":"deck_back","asset_id":14},
		{"id":"avatar_32","item_type":"avatar","asset_id":32},
		{"id":"throw_pomodoro","item_type":"throwable","asset_id":8}]:
		data.merge({"name":"Test","price":100,"is_available":true})
		shop._build_offer(data,0)
		assert(shop.grid.get_child(-1).get_node("Preview").texture != null)
	shop.queue_free()
	manager._account = null
	account.queue_free()
	await process_frame
	print("PASS: default cosmetics, ownership/isolation, all shop previews, two fronts and persistence")
	quit()
