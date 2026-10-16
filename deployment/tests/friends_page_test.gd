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
	assert(page.friends_box.size == Vector2(1160, 800))
	assert(page.stat_values.size() == 4)
	var account = root.get_node("AccountSession")
	var profile = root.get_node("AccountProfile")
	var previous_id = account.user_id
	var previous_profile = profile.profile
	account.user_id = "layout-test"
	profile.profile = {"id": "layout-test", "username": "Uomospazio", "public_id": "7P33XD", "games_played": 128, "wins": 76}
	page._refresh_account_panel()
	assert(page.account_name.text == "Uomospazio")
	assert(page.stat_values[2].get_parsed_text().strip_edges() == "59%")
	assert(page.stat_values[3].get_parsed_text().strip_edges() == "—")
	page.season_panel.apply_snapshot({"season": {"name": "STAGIONE 0", "remaining": 3600}, "own": {"rank": 2, "points": 150}, "stats": {"games_played": 128, "wins": 76}, "entries": [{"rank": 1, "username": "Primo", "points": 200}, {"rank": 2, "username": "Uomospazio", "points": 150}]})
	assert(page.stat_values[3].get_parsed_text().strip_edges() == "2°")
	# Avoid HTTP refresh during deterministic layout checks.
	page.season_panel.busy = true
	page._select_account_tab(true)
	assert(not page.account_name.visible and page.season_panel.visible)
	assert(page.account_box.texture.resource_path.ends_with("slotStagione.png"))
	assert(page.season_panel.rows.get_child_count() == 2)
	assert(page.season_panel.rows.get_child(0).get_theme_stylebox("panel").border_color == Color("8968E9"))
	assert(page.season_panel.rows.get_child(1).get_theme_stylebox("panel").border_color == Color("FFE66A"))
	assert(page.season_panel.rows.get_child(1).get_theme_stylebox("panel").border_width_left == 4)
	page._select_account_tab(false)
	assert(page.account_name.visible and not page.season_panel.visible)
	page.season_panel._info()
	var prize_dialog = page.get_child(-1)
	await process_frame
	await process_frame
	assert(not prize_dialog.cancel.visible)
	assert(prize_dialog.ok.text == "OK")
	assert(prize_dialog.ok.get_parent().alignment == BoxContainer.ALIGNMENT_CENTER)
	assert(prize_dialog.dialog_text.begins_with("1: 5000 monete"))
	assert(prize_dialog.dialog_text.contains("10: 300 monete"))
	assert(not prize_dialog.dialog_text.contains("punti"))
	assert(not prize_dialog.dialog_text.contains("Multiplayer"))
	prize_dialog.ok.pressed.emit()
	await process_frame
	if "--snapshot" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-friends-preview.png")
		page._select_account_tab(true)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-season-preview.png")
	var season_entries: Array = []
	page._select_account_tab(true)
	for place in range(1,21):
		season_entries.append({"rank": place, "username": "Player %d" % place, "points": 0.0})
	page.season_panel.apply_snapshot({"season": {"name": "STAGIONE 0", "remaining": 3600}, "own": {"rank": 17, "points": 0}, "entries": season_entries})
	for frame in range(5): await process_frame
	assert(page.season_panel.pinned_row.visible)
	assert(page.season_panel.pinned_row.position.y == page.season_panel.scroll.position.y + 352)
	assert(page.season_panel.rows.get_child_count() == 20, "Pinned card must not replace/remove fifth player")
	if "--snapshot" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-season-pinned.png")
	page.season_panel.scroll.scroll_vertical = 1056
	await process_frame
	assert(not page.season_panel.pinned_row.visible, "Hide duplicate when real rank 17 reaches fifth slot")
	page.season_panel.scroll.scroll_vertical = 0
	await process_frame
	assert(page.season_panel.pinned_row.visible, "Pin again when scrolling back up")
	page.season_panel.apply_snapshot({"season": {"name": "STAGIONE 0", "remaining": 3600}, "own": {"rank": 5, "points": 0}, "entries": season_entries})
	for frame in range(3): await process_frame
	assert(not is_instance_valid(page.season_panel.pinned_row), "Top five needs no pinned card")
	account.user_id = previous_id
	profile.profile = previous_profile
	page.query.text = "Space"
	page._show_search_results()
	assert(page.results.get_parent().visible and not page.contacts.get_parent().visible)
	manager.entries.clear()
	page.search_rows = [{"id": "new-friend", "username": "Space", "public_id": "TEST01"}]
	page.rendered_query = "Space"
	page._render_search_rows()
	page._apply_friend_action("new-friend", "request")
	var request_line = page.results.get_child(0).get_child(0)
	assert(request_line.get_child(-1).tooltip_text == "Annulla richiesta")
	assert(request_line.get_node("Identity").get_child(-1).text == "Richiesta inviata")
	page._apply_friend_action("new-friend", "cancel")
	assert(page.results.get_child(0).get_child(0).get_child(-1).tooltip_text == "Aggiungi amico")
	page.query.clear()
	page.update_contacts()
	assert(page.contacts.get_child_count() == 1)
	host.queue_free()
	print("PASS: friends layout, requests, invites, search visibility, empty state")
	quit()
