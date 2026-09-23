extends SceneTree

class Session extends "res://scenes/balatro/scripts/network_session.gd":
	var received: Array = []
	func _ready() -> void:
		set_process(false)
		object_thrown.connect(func(sender, target): received.append([sender, target]))

var apis: Array[MultiplayerAPI] = []

func _initialize() -> void:
	run.call_deferred()

func session(label: String, peer: MultiplayerPeer) -> Session:
	var branch := Node.new()
	branch.name = label
	root.add_child(branch)
	var api := SceneMultiplayer.new()
	set_multiplayer(api, branch.get_path())
	api.multiplayer_peer = peer
	apis.append(api)
	var result := Session.new()
	result.name = "NetworkSession"
	branch.add_child(result)
	return result

func run() -> void:
	var transport := WebSocketMultiplayerPeer.new()
	assert(transport.create_server(18914, "127.0.0.1") == OK)
	var server := session("Server", transport)
	server.dedicated = true
	var first := WebSocketMultiplayerPeer.new()
	var second := WebSocketMultiplayerPeer.new()
	assert(first.create_client("ws://127.0.0.1:18914") == OK)
	assert(second.create_client("ws://127.0.0.1:18914") == OK)
	var a := session("A", first)
	var b := session("B", second)
	var deadline := Time.get_ticks_msec() + 5000
	while first.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED or second.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		assert(Time.get_ticks_msec() < deadline)
		await process_frame
	server.members[first.get_unique_id()] = {"code": "TEST", "slot": 0}
	server.members[second.get_unique_id()] = {"code": "TEST", "slot": 1}
	server.rooms.TEST = {"rules": {"phase": "play", "players": [{"lives": 3}, {"lives": 3}]}, "people": [{"peer": first.get_unique_id()}, {"peer": second.get_unique_id()}]}
	a.send({"op": "throw", "target": 1})
	await create_timer(0.3).timeout
	assert(b.received == [[0, 1]], "Recipient did not receive throw")
	assert(a.received == [[0, 1]], "Sender did not receive acknowledgement")
	b.send({"op": "throw", "target": 0})
	await create_timer(0.3).timeout
	assert(a.received == [[0, 1], [1, 0]])
	a.send({"op": "throw", "target": 1})
	await create_timer(0.3).timeout
	assert(b.received.size() == 2, "Server failed to enforce cooldown")
	for api in apis: api.multiplayer_peer.close()
	print("PASS: bidirectional real WebSocket throws, sender acknowledgement, anti-spam")
	quit()
