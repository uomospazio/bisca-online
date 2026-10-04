extends SceneTree

class SearchStub extends Node:
	var queries: Array[String] = []
	func call_api(_method: String, body: Dictionary) -> Dictionary:
		queries.append(body.query)
		await get_tree().create_timer(0.45).timeout
		return {"ok": true, "data": [{"id": "result", "username": body.query + "io", "public_id": "ABC123"}]}
	func display_name(row: Dictionary) -> String:
		return str(row.username)

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
	assert(menu.friends_page.query.get_parent() == menu.friends_page.friends_box)
	assert(menu.friends_page.query.is_visible_in_tree())
	assert(not menu.friends_page.results.get_parent().visible)
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
	var stub := SearchStub.new()
	root.add_child(stub)
	var page = menu.friends_page
	page.manager = stub
	page.query.text = "Ma"
	page.query.text_changed.emit("Ma")
	await create_timer(0.4).timeout
	page.query.text = "Mar"
	page.query.text_changed.emit("Mar")
	await create_timer(1.3).timeout
	assert(stub.queries == ["Ma", "Mar"])
	assert(page.results.get_child(0).text == "Mario")
	page.query.text = ""
	page.query.text_changed.emit("")
	assert(page.contacts.get_parent().visible and not page.results.get_parent().visible)
	page.manager = manager
	stub.queue_free()
	menu.show_home()
	assert(not menu.friends_page.visible)
	menu.queue_free()
	await process_frame
	print("PASS Friends UI: apertura, richieste, badge, fallback codice e ritorno home")
	quit()
