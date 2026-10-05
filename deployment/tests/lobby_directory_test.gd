extends SceneTree

class RewardsStub extends Node:
	func verify(_jwt: String) -> String: return ""
	func observe(_room: Dictionary) -> void: pass

class Session extends "res://scenes/balatro/scripts/network_session.gd":
	func _ready() -> void: set_process(false)
	func _save() -> void: pass

func _initialize() -> void:
	_run.call_deferred()

func session(label: String, peer: MultiplayerPeer) -> Session:
	var branch := Node.new()
	branch.name = label
	root.add_child(branch)
	var api := SceneMultiplayer.new()
	set_multiplayer(api, branch.get_path())
	api.multiplayer_peer = peer
	var node := Session.new()
	node.name = "NetworkSession"
	branch.add_child(node)
	return node

func client(label: String) -> Session:
	var transport := WebSocketMultiplayerPeer.new()
	assert(transport.create_client("ws://127.0.0.1:18932") == OK)
	var node := session(label, transport)
	var deadline := Time.get_ticks_msec() + 5000
	while transport.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		assert(Time.get_ticks_msec() < deadline)
		await process_frame
	return node

func _run() -> void:
	var transport := WebSocketMultiplayerPeer.new()
	assert(transport.create_server(18932, "127.0.0.1") == OK)
	var server := session("Server", transport)
	server.dedicated = true
	server.rewards = RewardsStub.new()
	server.add_child(server.rewards)
	var host := await client("Host")
	host.send({"op": "create", "name": "Host", "directory_name": "#ABC123", "private": true})
	await create_timer(0.15).timeout
	assert(not host.latest.is_empty())
	var browser := await client("Browser")
	var listing: Array = []
	browser.lobby_directory_updated.connect(func(entries): listing.assign(entries))
	browser.send({"op": "list_lobbies"})
	await create_timer(0.15).timeout
	assert(listing.size() == 1)
	assert(listing[0].name == "Lobby di #ABC123" and listing[0].private)
	assert(not listing[0].has("code") and not listing[0].has("token"))
	var public_id: String = listing[0].id
	browser.send({"op": "join_public", "id": public_id, "name": "Guest"})
	await create_timer(0.15).timeout
	assert(browser.latest.is_empty())
	host.send({"op": "visibility", "private": false})
	await create_timer(0.15).timeout
	assert(not host.latest.private)
	browser.send({"op": "join_public", "id": public_id, "name": "Guest"})
	await create_timer(0.15).timeout
	assert(browser.latest.people.size() == 2)
	browser.send({"op": "visibility", "private": true})
	await create_timer(0.15).timeout
	assert(not host.latest.private)
	host.send({"op": "visibility", "private": true})
	await create_timer(0.15).timeout
	assert(browser.latest.private)
	var guest := await client("CodeGuest")
	guest.send({"op": "join", "code": host.room_code, "name": "CodeGuest"})
	await create_timer(0.15).timeout
	assert(guest.latest.people.size() == 3)
	server.rooms[host.room_code].stage = "deal"
	assert(server._lobby_directory().is_empty())
	print("PASS: directory, private code secrecy, public/private entry, host-only visibility and active-match filtering")
	for branch in [host.get_parent(), browser.get_parent(), guest.get_parent(), server.get_parent()]:
		branch.get_multiplayer().multiplayer_peer.close()
		branch.queue_free()
	await process_frame
	quit()
