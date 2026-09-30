extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	await process_frame
	var manager = root.get_node("FriendsManager")
	manager.entries = [{"id":"test", "username":"Mario", "public_id":"ABC123", "status":"pending", "incoming":true}]
	manager.changed.emit()
	assert(menu.friends_dot.visible)
	menu._show_friends()
	assert(menu.friends_page.is_visible_in_tree())
	assert(menu.friends_page.contacts.get_child_count() == 2)
	assert(not menu.friends_page.search_box.visible)
	var line = menu.friends_page.contacts.get_child(1).get_child(0)
	assert(line.get_child_count() == 4) # Presenza, identita', accetta, rifiuta.
	manager.entries[0].status = "accepted"
	manager.changed.emit()
	assert(not menu.friends_dot.visible)
	manager.entries[0]["invite_code"] = "ABC123"
	manager.changed.emit()
	assert(menu.friends_dot.visible)
	assert(menu.friends_page.contacts.get_child(1).get_child(0).get_child_count() == 5)
	assert(manager.display_name({"username":null,"public_id":"ABC123"}) == "#ABC123")
	manager.entries.clear()
	manager.changed.emit()
	assert(menu.friends_page.contacts.get_child_count() == 1)
	menu.show_home()
	assert(not menu.friends_page.visible)
	menu.queue_free()
	await process_frame
	print("PASS Friends UI: apertura, richieste, badge, fallback codice e ritorno home")
	quit()
