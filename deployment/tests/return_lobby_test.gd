extends SceneTree

class Session extends "res://scenes/balatro/scripts/network_session.gd":
	func _ready() -> void:
		set_process(false)

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

func _run() -> void:
	var transport := WebSocketMultiplayerPeer.new()
	assert(transport.create_server(18923, "127.0.0.1") == OK)
	var server := session("Server", transport)
	server.dedicated = true
	var client_peer := WebSocketMultiplayerPeer.new()
	assert(client_peer.create_client("ws://127.0.0.1:18923") == OK)
	var client := session("Client", client_peer)
	var deadline := Time.get_ticks_msec() + 5000
	while client_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		assert(Time.get_ticks_msec() < deadline)
		await process_frame
	var peer := client_peer.get_unique_id()
	var rules = preload("res://scenes/balatro/scripts/match_rules.gd").new()
	rules.start(2, 42)
	rules.phase = "finished"
	server.members[peer] = {"code": "TEST", "slot": 0}
	server.rooms.TEST = {"code": "TEST", "people": [
		{"name": "Host", "peer": peer, "bot": false, "token": "keep", "voice_id": "same", "avatar": "keep-photo"},
		{"name": "Bot", "peer": 0, "bot": true, "token": "", "voice_id": "bot"}],
		"rules": rules, "stage": "turn", "capacity": 8, "bots": true, "bot_count": 1,
		"options": {"lives": 4, "starting_cards": 3}, "rev": 0, "deadline": 0}
	client.send({"op": "return_lobby"})
	await create_timer(0.2).timeout
	assert(client.latest.stage == "lobby")
	assert(client.latest.code == "TEST" and client.latest.people.size() == 1)
	assert(server.rooms.TEST.people[0].token == "keep")
	assert(server.rooms.TEST.people[0].avatar == "keep-photo")
	client.send({"op": "settings", "lives": 5, "starting_cards": 2, "bots": true, "bot_count": 2})
	await create_timer(0.2).timeout
	client.send({"op": "start"})
	await create_timer(0.2).timeout
	assert(client.latest.stage == "deal" and client.latest.people.size() == 3)
	assert(client.latest.hand_size == 2 and client.latest.players[0].lives == 5)
	client_peer.close()
	transport.close()
	print("PASS: return to same lobby, preserved profile, editable settings, fresh bots and restart")
	quit()
