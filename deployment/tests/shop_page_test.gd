extends SceneTree
class Account extends Node:
	var user_id := "ui-test"
	func is_authenticated() -> bool: return true
class Shop extends "res://scenes/balatro/scripts/shop_manager.gd":
	func _ready() -> void: pass
	func refresh() -> void: pass
	func refresh_daily() -> void: pass

func _initialize() -> void: run.call_deferred()

func run() -> void:
	create_timer(20).timeout.connect(func(): push_error("Shop test timed out"); quit(1))
	var account := Account.new()
	root.add_child(account)
	var original := root.get_node("ShopManager")
	root.remove_child(original)
	original.queue_free()
	var manager := Shop.new()
	manager.name = "ShopManager"
	root.add_child(manager)
	manager._account = account
	manager._owner = account.user_id
	manager.catalog_ready = true
	manager.inventory_ready = true
	manager.daily_refresh_available = true
	manager._daily_until = Time.get_ticks_msec()+3600000
	for type in ["deck_back","avatar","throwable"]:
		for index in [2,3]:
			var id := "%s_%d" % [type,index]
			manager._daily_ids.append(id)
			manager._catalog[id] = {"id":id,"name":id,"item_type":type,"price":500 if type=="deck_back" else (100 if type=="avatar" else 200),"asset_id":index,"is_available":true,"is_default":false,"rarity":"common"}
	var items := manager.get_daily_items()
	assert(items.size()==6)
	for i in range(6): assert(items[i].item_type==["deck_back","avatar","throwable"][i%3])
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	if "--visual" in OS.get_cmdline_user_args():
		var background := TextureRect.new()
		root.add_child(background)
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.texture = load("res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/sfondoViola.png")
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(menu)
	await process_frame
	menu._show_shop()
	await create_timer(0.4).timeout
	var page: Control = menu.shop_page
	assert(page.grid.get_child_count()==6)
	assert(page.fixed_controls.size()==6)
	assert(page.art_ui.video.disabled and page.art_ui.reroll.disabled,"No real desktop ads")
	assert(page.art_ui.reward_caption.text=="+50")
	assert(page.art_ui.countdown.text!="--:--:--")
	for index in range(6):
		var offer: Control = page.grid.get_child(index)
		assert(offer.get_node("Preview").texture!=null)
		assert(not offer.has_meta("menu_button_hover"))
		assert(offer.get_node("Preview").has_meta("menu_button_hover"))
		var hit := offer.get_global_transform_with_canvas()*(offer.size/2)
		assert(page._item_at_position(hit)==items[index].id)
	page._ask_purchase(items[0].id)
	assert(page.purchase_dialog.visible and page.pending_price==500)
	page.purchase_dialog.hide()
	page.art_ui.wheel.pressed.emit()
	assert(not page.purchase_dialog.visible and menu.shop_page.visible)
	assert(page.fortune_wheel.visible and not page.art_ui.visible)
	assert(page._item_at_position(Vector2(960,540))=="")
	if "--wheel" not in OS.get_cmdline_user_args(): page.fortune_wheel._back_to_shop()
	if "--visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/bisca-wheel.png" if "--wheel" in OS.get_cmdline_user_args() else "/private/tmp/bisca-shop-six.png")
	manager._inventory[items[0].id] = {"item_id":items[0].id}
	manager.changed.emit()
	assert(not page.item_previews.has(items[0].id))
	assert(page.grid.get_child(0).get_node("PriceTag/Price").text=="POSSEDUTO")
	menu.show_home()
	assert(not page.visible)
	menu._show_shop()
	assert(page.grid.get_child_count()==6)
	menu.queue_free()
	account.queue_free()
	await process_frame
	print("PASS: six categorized offers, purchase hit areas, owned state, ad artwork, countdown, wheel placeholder, navigation")
	quit()
