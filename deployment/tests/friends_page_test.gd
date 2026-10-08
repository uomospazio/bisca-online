extends SceneTree

class Host extends Control:
	const KIDS_FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
	func show_home() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var host := Host.new()
	root.add_child(host)
	host.size = Vector2(1920, 1080)
	var page = preload("res://scenes/balatro/scripts/friends_page.gd").new()
	host.add_child(page)
	page.setup(host)
	var manager := root.get_node("FriendsManager")
	manager.entries = [
		{"id":"1", "username":"Gambolosoco", "public_id":"ABC123", "status":"accepted", "online":true},
		{"id":"2", "username":"Son_of_rocio", "public_id":"OT05D2", "status":"pending", "incoming":true},
		{"id":"3", "username":"Giangibis", "public_id":"T57C43", "status":"pending", "incoming":false},
		{"id":"4", "username":"Space", "public_id":"NJC4AJ", "status":"accepted", "invite_code":"TEST12"}
	]
	page.update_contacts()
	manager.entries[0]["avatar"] = preload("res://scenes/balatro/scripts/avatar_catalog.gd").encoded(0)
	manager.entries[1]["avatar"] = "invalid-photo"
	page.update_contacts()
	for i in range(5): await process_frame
	assert(page.contacts.get_child_count() == 4)
	assert(page.contacts.get_child(0).find_child("FriendPhoto", true, false) != null)
	assert(page.contacts.get_child(1).find_child("FriendPhoto", true, false) == null)
	for tile in page.contacts.get_children():
		assert(tile.size.x <= 1304 and tile.size.y == 110)
		var identity = tile.find_child("Identity", true, false)
		assert(identity != null and identity.size.x > 100)
	var invite_line = page.contacts.get_child(3).get_child(0)
	var buttons := 0
	for child in invite_line.get_children():
		if child is Button: buttons += 1
	assert(buttons == 2, "Invites must have only reject and accept actions")
	assert(page.friends_box.size == Vector2(1400, 790))
	if "--snapshot" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-friends-preview.png")
	page.query.text = "Space"
	page._show_search_results()
	assert(page.results.get_parent().visible and not page.contacts.get_parent().visible)
	manager.entries.clear()
	page.query.clear()
	page.update_contacts()
	assert(page.contacts.get_child_count() == 1)
	host.queue_free()
	print("PASS: friends layout, requests, invites, search visibility, empty state")
	quit()
