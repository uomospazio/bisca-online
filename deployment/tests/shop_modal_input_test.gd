extends SceneTree

class Shop extends "res://scenes/balatro/scripts/shop_page.gd":
	var selections := 0
	func _item_at_position(_position: Vector2) -> String: return "avatar_2"
	func _ask_purchase(_id: String) -> void: selections += 1

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var shop := Shop.new()
	root.add_child(shop)
	var dialog := preload("res://scenes/balatro/scripts/menu_dialog.gd").new()
	root.add_child(dialog)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	shop._input(touch)
	assert(not shop.touch_item_id.is_empty())
	dialog.show()
	touch.pressed = false
	shop._input(touch)
	assert(shop.selections==0 and shop.touch_item_id.is_empty())
	touch.pressed = true
	shop._input(touch)
	dialog.hide() # Closing a modal must not complete a shop tap.
	touch.pressed = false
	shop._input(touch)
	assert(shop.selections==0)
	touch.pressed = true
	shop._input(touch)
	touch.pressed = false
	shop._input(touch)
	assert(shop.selections==1,"A fresh tap works after closing the popup")
	dialog.queue_free()
	shop.queue_free()
	await process_frame
	print("PASS: modal blocks underlying shop taps, clears pending touches, fresh tap works after closing")
	quit()
