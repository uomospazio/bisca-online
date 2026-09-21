extends SceneTree

# Three real MultiplayerAPI instances exercise the production RPC relay.
class Session extends "res://scenes/balatro/scripts/network_session.gd":
	var received: Array = []
	func _ready() -> void:
		set_process(false)
	@rpc("authority", "call_remote", "reliable")
	func receive_voice_signal(sender_slot: int, data: Dictionary) -> void:
		received.append({"slot": sender_slot, "data": data})

var branches: Array[Node] = []
var apis: Array[MultiplayerAPI] = []

func _initialize() -> void:
	_run.call_deferred()

func make_session(label: String, peer: MultiplayerPeer) -> Session:
	var branch := Node.new()
	branch.name = label
	root.add_child(branch)
	branches.append(branch)
	var api := SceneMultiplayer.new()
	set_multiplayer(api, branch.get_path())
	api.multiplayer_peer = peer
	apis.append(api)
	var session := Session.new()
	session.name = "NetworkSession"
	branch.add_child(session)
	return session

func wait_frames(count: int) -> void:
	for i in count:
		await process_frame

func _run() -> void:
	var server_peer := WebSocketMultiplayerPeer.new()
	assert(server_peer.create_server(18913, "127.0.0.1") == OK)
	var server := make_session("Server", server_peer)
	server.dedicated = true
	var peer_a := WebSocketMultiplayerPeer.new()
	var peer_b := WebSocketMultiplayerPeer.new()
	assert(peer_a.create_client("ws://127.0.0.1:18913") == OK)
	assert(peer_b.create_client("ws://127.0.0.1:18913") == OK)
	var a := make_session("A", peer_a)
	var b := make_session("B", peer_b)
	var deadline := Time.get_ticks_msec() + 5000
	while peer_a.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED or peer_b.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		assert(Time.get_ticks_msec() < deadline, "WebSocket connection timeout")
		await process_frame
	server.members[peer_a.get_unique_id()] = {"code": "TEST", "slot": 0}
	server.members[peer_b.get_unique_id()] = {"code": "TEST", "slot": 1}
	server.rooms["TEST"] = {"code": "TEST", "people": [
		{"peer": peer_a.get_unique_id(), "voice_id": "a", "bot": false},
		{"peer": peer_b.get_unique_id(), "voice_id": "b", "bot": false}]}
	# Round trip through JSON exactly as in the browser bridge, then real RPCs.
	for payload in [
		{"type": "ready"},
		{"type": "description", "description": {"type": "offer", "sdp": "v=0\r\na=ice-ufrag:test\r\n"}},
		{"type": "candidate", "candidate": {"candidate": "candidate:test", "sdpMLineIndex": 0, "sdpMid": "0"}}]:
		payload.merge({"room": "TEST", "from_id": "a", "to_id": "b", "epoch": "test-epoch"})
		var decoded: Dictionary = JSON.parse_string(JSON.stringify(payload))
		a.voice_signal.rpc_id(1, 1, decoded)
	await create_timer(0.25).timeout
	assert(b.received.size() == 3, "Production server dropped voice signaling")
	assert(b.received[1].data.description.sdp == "v=0\r\na=ice-ufrag:test\r\n")
	assert(b.received[2].data.candidate.sdpMLineIndex == 0)
	b.voice_signal.rpc_id(1, 0, {"type": "ready", "room": "TEST", "from_id": "b", "to_id": "a", "epoch": "b-epoch"})
	await create_timer(0.25).timeout
	assert(a.received.size() == 1)
	for api in apis:
		api.multiplayer_peer.close()
	print("PASS: production WebSocket voice relay, bidirectional RPC, SDP line endings and ICE candidate JSON")
	quit()
